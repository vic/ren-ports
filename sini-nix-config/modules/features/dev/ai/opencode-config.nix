# OpenCode: opencode.json (providers, model, permission, MCP) and tui.json.
{ ... }:
{
  ren.aspects.dev-ai-agents-opencode.homeManager =
    {
      config,
      lib,
      ninfer-endpoints ? [ ],
      agent-extensions ? { },
      ...
    }:
    let
      # ponytail: first endpoint wins — key by hostname if a second inference host appears.
      ninfer = if ninfer-endpoints == [ ] then null else builtins.head ninfer-endpoints;

      extensionsList = lib.flatten agent-extensions;
      collectedMcp = lib.foldl' (acc: e: acc // (e.mcpServers or { })) { } extensionsList;

      formatMcpForOpencode = import ./_opencode-mcp.nix lib;

      # `provider` is a MAP of provider-id -> ProviderConfig; baseURL lives under `options`, the model is
      # an entry in `models` (https://opencode.ai/config.json $defs/ProviderConfig).
      providerKey = if ninfer != null then "ninfer" else "ollama";
      modelKey = if ninfer != null then ninfer.modelId else "qwen3.8:27b";

      opencodeConfig = {
        "$schema" = "https://opencode.ai/config.json";

        provider.${providerKey} = {
          # openai-compatible is the /v1/chat/completions client (@ai-sdk/openai is for /v1/responses).
          npm = "@ai-sdk/openai-compatible";
          name = if ninfer != null then "NInfer (${ninfer.hostname})" else "Ollama (cortex-cuda)";
          options.baseURL =
            if ninfer != null then
              "http://${ninfer.ip}:${toString ninfer.port}/v1"
            else
              "http://10.9.2.2:11434/v1";
          models.${modelKey} = {
            name = if ninfer != null then "Qwen 3.8 27B (NInfer sm_86, MTP3)" else "Qwen 3.8 27B (Ollama)";
            reasoning = true;
          }
          // lib.optionalAttrs (ninfer != null) {
            # A custom provider must state limits or opencode cannot track remaining context.
            limit = {
              context = ninfer.maxContext;
              output = ninfer.maxTokens;
            };
          };
        };

        # hyperqwen is the resident engine on the inference guest (owner, 2026-10-10); the provider above
        # stays as standby. The key is an agenix secret (services.ai.hyperqwen-client), read at runtime.
        provider.hyperqwen = {
          npm = "@ai-sdk/openai-compatible";
          name = "HyperQwen (cortex-cuda)";
          options = {
            baseURL = "http://10.9.2.2:18020/v1";
            apiKey = "{file:${config.age.secrets.hyperqwen-api-key.path}}";
          };
          models."qwen3.8-27b" = {
            name = "Qwen 3.8 27B (HyperQwen vLLM, CTX=long)";
            reasoning = true;
            limit = {
              context = 150000;
              output = 32768;
            };
          };
        };

        # Without `small_model` opencode routes auxiliary calls to a hosted default, i.e. off-box.
        model = "hyperqwen/qwen3.8-27b";
        small_model = "hyperqwen/qwen3.8-27b";
        permission = {
          bash = "allow";
          edit = "allow";
          read = "allow";
          web_fetch = "allow";
        };
        mcp = formatMcpForOpencode collectedMcp;
      };

      tuiConfig = {
        "$schema" = "https://opencode.ai/tui.json";
        theme = "dark";
      };
    in
    {
      home.file = {
        ".config/opencode/opencode.json".text = builtins.toJSON opencodeConfig;
        ".config/opencode/tui.json".text = builtins.toJSON tuiConfig;
      };
    };
}
