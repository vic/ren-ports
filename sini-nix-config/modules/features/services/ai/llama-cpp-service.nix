# llama-cpp: llama-server on a single CUDA GPU, plus endpoint emission (see llama-cpp.nix).
{ ren, lib, ... }:
let
  models = (import ./_llama-cpp-models.nix).models;
in
{
  ren.aspects.svc-ai-llama-cpp = {
    llama-cpp-endpoints =
      { host, ... }:
      {
        hostname = host.name;
        ip = builtins.head (ren.helpers.ipv4Of host);
        port = 8080;
      };

    nixos =
      { host, pkgs, ... }:
      let
        cfg = host.svc-ai-llama-cpp;
        entry = models.${cfg.model};
        modelArtifact = pkgs.fetchurl {
          inherit (entry) url hash;
          name = baseNameOf entry.url;
        };
      in
      {
        # Target single CUDA GPU (RTX 3090 Ti inside MicroVM)
        services.llama-cpp = {
          enable = true;
          package = pkgs.llama-cpp.override { cudaSupport = true; };
          settings =
            entry.settings or { }
            // lib.optionalAttrs (cfg.nCpuMoe != null) { n-cpu-moe = cfg.nCpuMoe; }
            // {
              model = if cfg.modelPath != null then cfg.modelPath else "${modelArtifact}";
              ctx-size = cfg.contextSize;
              inherit (cfg) parallel;
              # `--cache-idle-slots` is enabled by default and is what actually
              # populates the budget above; the aspect used to pass
              # `--no-cache-idle-slots` alongside it, reserving 48 GiB of prompt
              # cache and then switching off the only thing that fills it. Left at
              # the default deliberately: with parallel = 1 a second conversation
              # evicts the first, and saving the idle slot is what keeps the next
              # turn from re-prefilling the whole transcript.
              cache-ram = cfg.cacheRamMB; # host prompt-cache budget (not active-KV spillover)
              cache-type-k = cfg.kvCacheType;
              cache-type-v = cfg.kvCacheType;
              n-gpu-layers = 99;
              flash-attn = "on";
              kv-unified = true; # one KV buffer shared across sequences (not host spillover)
              # No reasoning-preserve, and no preserve_thinking in
              # chat-template-kwargs: both were Qwen3.8 carry-overs that
              # gpt-oss cannot honour. The server rejects the flag out loud
              # at startup -- "chat template does NOT support preserving
              # reasoning, --reasoning-preserve has no effect" -- while the
              # template kwarg was accepted and silently dropped, which is
              # the worse of the two failures.

              # gpt-oss-20b answers to the same name the in-cluster instances
              # answer to (kubernetes.services.ai.llama-cpp.instances.gpt-oss.modelAlias),
              # so a client addressing the pool reaches this host with its `model`
              # field unchanged. Without an alias the only id llama-server accepts
              # is the store path of the GGUF, which changes per build.
              inherit (entry) alias;

              reasoning-budget = 4096; # force-close a runaway thought (upstream default -1 is unbounded)
              batch-size = cfg.batchSize;
              ubatch-size = cfg.ubatchSize;
              host = "0.0.0.0";
              port = 8080;
            };
        };

        # Mutex GPU VRAM against Ollama so only one model engine holds VRAM at a time
        systemd.services.llama-cpp = {
          unitConfig = {
            Conflicts = [ "ollama.service" ];
          };
        };

        networking.firewall.allowedTCPPorts = [ 8080 ];
      };
  };
}
