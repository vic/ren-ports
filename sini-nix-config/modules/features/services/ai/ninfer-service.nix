# ninfer: engine package, store-fetched model, serve args, systemd unit (see ninfer.nix).
{
  ren,
  lib,
  inputs,
  ...
}:
let
  inherit (import ./_ninfer-models.nix) models;
in
{
  ren.aspects.svc-ai-ninfer.nixos =
    { host, pkgs, ... }:
    let
      cfg = host.svc-ai-ninfer;
      ninfer = import ./_ninfer-package.nix { inherit inputs pkgs; };

      # Content-addressed acquisition: the guest mounts the host's /nix/store
      # over virtiofs, so a store path is readable in the VM and the model is
      # present the moment the closure is. No first-boot download step, and
      # nothing for the unit to race against.
      modelArtifact = pkgs.fetchurl {
        inherit (models.${cfg.model}) url hash;
        name = baseNameOf models.${cfg.model}.url;
      };
      model = if cfg.modelPath != null then cfg.modelPath else "${modelArtifact}";

      args = [
        "${ninfer}/bin/ninfer-serve"
        model
        "--host"
        "0.0.0.0"
        "--port"
        (toString cfg.port)
        "--model-id"
        cfg.modelId
        "--max-context"
        (toString cfg.maxContext)
        "--kv-capacity"
        cfg.kvCapacity
        "--kv-dtype"
        cfg.kvDtype
        "--max-concurrency"
        (toString cfg.maxConcurrency)
        "--pending-timeout-ms"
        (toString cfg.pendingTimeoutMs)
        "--prefill-chunk"
        (toString cfg.prefillChunk)
        "--default-max-tokens"
        (toString cfg.maxTokens)
      ]
      ++ lib.optionals (cfg.draftTokens > 0) [
        "--spec"
        "mtp"
        "--draft-tokens"
        (toString cfg.draftTokens)
        "--lm-head-draft"
      ]
      ++ lib.optional cfg.preserveThinking "--preserve-thinking"
      ++ lib.optionals (cfg.thinkingBudget != null) [
        "--default-thinking-budget"
        (toString cfg.thinkingBudget)
      ];
    in
    {
      # `ninfer` CLI for one-shot generation against the same artifact. The
      # upstream download helper is deliberately absent: acquisition is the
      # store's job, not an operator's.
      environment.systemPackages = [ ninfer ];

      systemd.services.ninfer = {
        description = "NInfer-3090 inference server (Qwen3.8-27B, sm_86)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = lib.optional cfg.autoStart "multi-user.target";

        # One 24 GB card holds one engine: starting this stops the others.
        conflicts = [
          "llama-cpp.service"
          "ollama.service"
        ];

        # libcuda.so.1 ships with the NVIDIA driver, not the CUDA toolkit.
        environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";

        serviceConfig = {
          ExecStart = lib.escapeShellArgs args;
          User = "ninfer";
          Group = "ninfer";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
