# HyperQwen: image bundle, pinned checkpoints seeded on start, the podman unit (see hyperqwen.nix).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  inherit (import ./_hyperqwen-models.nix { inherit lib; }) hubFiles models;
in
{
  ren.aspects.svc-ai-hyperqwen.nixos =
    {
      config,
      host,
      pkgs,
      ...
    }:
    let
      cfg = host.svc-ai-hyperqwen;
      bundle = import ./_hyperqwen-bundle.nix { inherit pkgs; };
      dir = "/cache/var/lib/private/hyperqwen";

      checkpoint = m: hubFiles pkgs m.repo m.rev m.files;
      base = models."qwen3.8-27b";
      served = models.${cfg.model};
      dflash2 =
        hubFiles pkgs "syvai/Qwen3.8-27B-DFlash2-W4A16" "4d30ec736ffc6b8688dc2ae2b502d9b48bdec279"
          {
            "config.json" = "sha256-YdYnb+jXYpUjLLAtJsuw0pwlVlkR9QRB53nIjJIgxVY=";
            "model.safetensors" = "sha256-7CaZbmoHRate24VxFyIM4eIZrVJPcebhSbcDgElH2Oc=";
          };
      froggeric = pkgs.fetchurl {
        url = "https://huggingface.co/froggeric/Qwen-Fixed-Chat-Templates/resolve/855bffc49448e299789730ff92c9b8d834d6cc14/chat_template.jinja";
        name = "froggeric-v22.5.jinja";
        hash = "sha256-5XaEuuQVYhGlVHPFpjvpdqQFo3q1vlrg5avx31NJxLI=";
      };

      # A store path is read-only and prepare rewrites the checkpoint in place,
      # so each is copied once per pinned revision.
      seed = src: name: ''
        if [ ! -e ${dir}/models/${name}/.seeded-${baseNameOf src} ]; then
          rm -rf ${dir}/models/${name}
          mkdir -p ${dir}/models/${name}
          cp -L --no-preserve=mode ${src}/* ${dir}/models/${name}/
          touch ${dir}/models/${name}/.seeded-${baseNameOf src}
        fi
      '';
      env = {
        PORT = toString cfg.port;
        HOST = "0.0.0.0";
        # The fast variant is an unpinned Hub download; prepare skips it.
        FAST_VARIANT = "0";
        HF_HUB_OFFLINE = "1";
      }
      // lib.optionalAttrs served.prepared {
        MODEL = "/app/models/${served.dir}";
      }
      // lib.optionalAttrs (cfg.template == "froggeric") {
        EXTRA_ARGS = "--chat-template /templates/froggeric.jinja";
      }
      // cfg.env;
    in
    {
      systemd.services.hyperqwen = {
        description = "HyperQwen (patched vLLM) serving Qwen3.8-27B";
        after = [ "nvidia-container-toolkit-cdi-generator.service" ];
        requires = [ "nvidia-container-toolkit-cdi-generator.service" ];
        conflicts = [
          "ninfer.service"
          "llama-cpp.service"
          "ollama.service"
        ];
        wantedBy = lib.optional cfg.autoStart "multi-user.target";
        path = [ config.virtualisation.podman.package ];
        preStart = ''
          mkdir -p ${dir}/cache
          # prepare checks the base on every start, so it is seeded whichever is served.
          ${seed (checkpoint base) base.dir}
          ${lib.optionalString (cfg.model != "qwen3.8-27b") (seed (checkpoint served) served.dir)}
          ${seed dflash2 "Qwen3.8-27B-DFlash2-W4A16"}
        '';
        script = ''
          exec podman run --rm --replace --name hyperqwen \
            --network host --ipc host --device nvidia.com/gpu=all \
            --env-file ${bundle}/env --env-file ${config.age.secrets.hyperqwen-env.path} \
            ${lib.concatStrings (lib.mapAttrsToList (k: v: "-e ${lib.escapeShellArg "${k}=${v}"} ") env)}\
            -v ${dir}/models:/app/models -v ${dir}/cache:/cache \
            -v ${froggeric}:/templates/froggeric.jinja:ro \
            --workdir /app --rootfs ${bundle}/rootfs:O \
            bash docker/entrypoint.sh single
        '';
        # First start requantizes, then compiles CUDA graphs and JITs FlashInfer.
        serviceConfig.TimeoutStartSec = "infinity";
      };
    };
}
