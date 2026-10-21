# Ollama, local LLM inference server. Emits ollama-endpoints so consumers (open-webui) discover instances.
{ ren, lib, ... }:
{
  ren.kinds.machine.svc-ai-ollama = ren.lib.opt (lib.types.submodule {
    options.acceleration = lib.mkOption {
      type = lib.types.enum [
        "rocm"
        "cuda"
        "cpu"
      ];
      default = "cpu";
      description = "GPU acceleration backend";
    };
  }) { };

  ren.aspects.svc-ai-ollama = {
    ollama-endpoints =
      { host, ... }:
      {
        hostname = host.name;
        ip = builtins.head (ren.helpers.ipv4Of host);
        port = 11434;
      };

    nixos =
      { host, pkgs, ... }:
      {
        services.ollama = {
          enable = true;
          user = "ollama";
          group = "ollama";
          openFirewall = true;

          host = "0.0.0.0";
          port = 11434;

          home = "/cache/var/lib/private/ollama";
          models = "/cache/var/lib/private/ollama/models";

          package =
            if host.svc-ai-ollama.acceleration == "rocm" then
              pkgs.ollama-rocm
            else if host.svc-ai-ollama.acceleration == "cuda" then
              pkgs.ollama-cuda
            else
              pkgs.ollama-cpu;

          environmentVariables = {
            OLLAMA_FLASH_ATTENTION = "true";
            OLLAMA_CONTEXT_LENGTH = "262144";
            OLLAMA_KV_CACHE_TYPE = "q4_0";
            OLLAMA_KEEP_ALIVE = "10m";
            OLLAMA_MAX_LOADED_MODELS = "4";
            OLLAMA_MAX_QUEUE = "64";
            OLLAMA_NUM_PARALLEL = "1";
            OLLAMA_ORIGINS = "*";
          };

          loadModels = [
            "gpt-oss:20b"
            "qwen3.8:27b"
          ];
        };
      };

    cache.directories = [
      {
        directory = "/var/lib/private/ollama";
        user = "ollama";
        group = "ollama";
        mode = "0700";
      }
    ];
  };
}
