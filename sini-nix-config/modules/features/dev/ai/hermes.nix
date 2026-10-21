# Hermes Agent (github:NousResearch/hermes-agent): terminal AI agent on local high-context inference.
# CLI, Electron app and declarative config come from upstream's flake HM module; hermes-hud/one from llm-agents.
{ ren, inputs, ... }:
{
  ren.aspects.dev-ai-agents-hermes = {
    flake-inputs.hermes-agent.url = "github:NousResearch/hermes-agent";

    # ninfer-client admits this host to the inference guest, hyperqwen's port included.
    includes = with ren.aspects; [
      svc-ai-ninfer-client
      svc-ai-hyperqwen-client
    ];

    homeManagerModules = [ inputs.hermes-agent.homeManagerModules.default ];

    homeManager =
      {
        config,
        host,
        is,
        lib,
        pkgs,
        ...
      }:
      let
        llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        # Electron shells need a session; slab (Termux) has no display.
        hasGui = is ren.aspects.workstation host || is ren.aspects.darwin-workstation host;
      in
      {
        programs.hermes-agent = {
          enable = true;
          desktop.enable = hasGui;
        };

        services.hermes-agent = {
          enable = true;
          # Terminal agent: no messaging gateway (the unit would need lingering).
          gateway.enable = false;
          settings = {
            # hyperqwen is the resident engine on the inference guest; key is an agenix secret read at runtime.
            providers.hyperqwen = {
              name = "HyperQwen (cortex-cuda)";
              api = "http://10.9.2.2:18020/v1";
              transport = "chat_completions";
              key_cmd = "cat ${config.age.secrets.hyperqwen-api-key.path}";
              default_model = "qwen3.8-27b";
              context_length = 150000;
            };
            model = {
              provider = "hyperqwen";
              default = "qwen3.8-27b";
              context_length = 150000;
              max_tokens = 32768;
            };
            # Loaded Qwen3.8 template only exposes low/medium/xhigh (plus none); minimal/high return 400.
            agent.reasoning_effort = "medium";
          };
        };

        home.packages = [ llm.hermes-hud ] ++ lib.optionals hasGui [ llm.hermes-one ];

        programs.git.ignores = [ "/.hermes/" ];
      };

    persistHome.directories = [ ".hermes" ];
  };
}
