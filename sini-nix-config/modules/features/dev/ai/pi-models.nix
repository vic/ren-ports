# pi: provider endpoints (models.json), keyless auth stubs (auth.json), omp models.yml.
{ ... }:
{
  ren.aspects.dev-ai-agents-pi.homeManager =
    {
      config,
      lib,
      ninfer-endpoints,
      ...
    }:
    let
      # ponytail: first endpoint wins — key the provider by hostname if a
      # second inference host ever appears.
      ninfer = if ninfer-endpoints == [ ] then null else builtins.head ninfer-endpoints;

      hyperqwen = import ./_pi/hyperqwen.nix config;
    in
    {
      # omp writes ~/.omp/agent/config.yml itself (/settings), so only models.yml is
      # managed. With hyperqwen the only provider, it is omp's first available model.
      home.file.".omp/agent/models.yml".text = builtins.toJSON { providers = { inherit hyperqwen; }; };

      # Deploy dummy auth keys for keyless local inference servers (ollama & llama-cpp)
      home.file.".pi/agent/auth.json".text = builtins.toJSON (
        {
          ollama = {
            type = "api_key";
            key = "ollama";
          };
          llama-cpp = {
            type = "api_key";
            key = "llama-cpp";
          };
        }
        // lib.optionalAttrs (ninfer != null) {
          ninfer = {
            type = "api_key";
            key = "ninfer";
          };
        }
      );

      # Configure model provider endpoints for remote cortex-cuda MicroVM
      home.file.".pi/agent/models.json".text = builtins.toJSON {
        providers = {
          # NInfer serves the same Qwen3.8-27B from the same guest, but on its own port and with a
          # strictly validated model id, so endpoint and id both come off the ninfer-endpoints quirk.
          # Not the default provider: the unit conflicts with llama-cpp over the GPU and does not
          # auto-start, so selecting it in-session is the deliberate half of the A/B.
        }
        // lib.optionalAttrs (ninfer != null) {
          ninfer = {
            name = "NInfer (${ninfer.hostname})";
            baseUrl = "http://${ninfer.ip}:${toString ninfer.port}/v1";
            api = "openai-completions";
            apiKey = "ninfer";
            compat = {
              # Genuine NInfer capabilities. The loaded Qwen3.8 chat template exposes only
              # low/medium/xhigh (plus none): pi's minimal/high/max levels return HTTP 400
              # reasoning_effort_not_supported.
              supportsDeveloperRole = true;
              supportsReasoningEffort = true;
            };
            models = [
              {
                id = ninfer.modelId;
                name = "Qwen 3.8 27B (NInfer sm_86, MTP3)";
                reasoning = true;
                contextWindow = ninfer.maxContext;
                maxTokens = ninfer.maxTokens;
              }
            ];
          };
        }
        // { inherit hyperqwen; }
        // import ./_pi/local-providers.nix;
      };
    };
}
