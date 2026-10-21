# ai-claude: Claude Code through the LiteLLM proxy, plannotator + tuicr
{ ren, inputs, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.ai-claude.homeManager =
    {
      config,
      lib,
      fleet,
      pkgs,
      user,
      ...
    }:
    let
      claudePkg = (addax.omni pkgs).unified.llm-agents-nix.packages.claude-code;

      # Both variants talk to the LiteLLM proxy on mensa-nixos (modules/aspects/services/litellm.nix). It has no master
      #  key, so the key is a placeholder, but it must be sent as `x-litellm-api-key`: without that header LiteLLM takes
      #  `Authorization` as its own key and strips the subscription OAuth token instead of forwarding it to Anthropic.
      litellmUrl = "https://litellm.${fleet.tailnet}";
      litellmEnv = {
        ANTHROPIC_BASE_URL = litellmUrl;
        ANTHROPIC_CUSTOM_HEADERS = "x-litellm-api-key: tailnet";
      };

      # `claude-cerit` = same binary, same shared user settings/plugins/skills,
      # re-pointed at the CERIT-SC models behind the proxy (which forwards the
      # Anthropic Messages API to CERIT untranslated) by a `--settings` overlay.
      # Claude Code has NO cross-provider
      # fallback: its `fallbackModel` only fires on 529-overload/unavailable and
      # only among Anthropic's own catalog, so usage-credit exhaustion of the
      # subscription can only ever be handled by switching to this wrapper —
      # there is nothing to configure on the `claude` side.
      # The gateway id list is dynamic (LiteLLM); any `cerit/<id>` works via --model or
      # ANTHROPIC_MODEL, no allowlist is needed. `kimi` = CERIT's alias for the
      # latest Kimi (now K3), the best coding model offered by the gateway today.
      ceritSettingsFile = pkgs.writers.writeJSON "claude-cerit-settings.json" {
        # A key from `apiKeyHelper` keeps OAuth/keychain from being consulted, so this
        # variant works without a Claude login; the proxy sends its own CERIT key upstream.
        apiKeyHelper = "echo tailnet";
        model = "cerit/kimi";
        env = litellmEnv // {
          ANTHROPIC_MODEL = "cerit/kimi";
          ANTHROPIC_SMALL_FAST_MODEL = "cerit/mini";
          # Fetch ${ANTHROPIC_BASE_URL}/v1/models and offer every gateway model
          # in /model (cached to gateway-models.json), instead of only the static
          # Anthropic lineup. This is how "all CERIT models" reach the picker.
          CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
        };
      };
      claudeCerit = pkgs.writeShellApplication {
        name = "claude-cerit";
        runtimeInputs = [ claudePkg ];
        text = ''
          # --settings merges ON TOP of the user settings file, so the shared
          # config below (permissions, marketplaces, plugins, skills, rules)
          # stays in force; only the provider keys differ per variant.
          exec claude --settings "${ceritSettingsFile}" "$@"
        '';
      };
    in
    {
      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        configDir = "${config.xdg.configHome}/claude";
        package = (addax.omni pkgs).unified.llm-agents-nix.packages.claude-code;
        settings = {
          permissions.defaultMode = "auto";
          # The subscription login is kept; only the endpoint moves to the proxy.
          env = litellmEnv;
        };
        marketplaces = {
          inherit (inputs) plannotator;
        };
        plugins = {
          plannotator = "${inputs.plannotator}/apps/hook";
        };
        # Slash-command skills shipped separately from the hook plugin above
        # (normally installed by the plugin's installer).
        skills = {
          plannotator-review = "${inputs.plannotator}/apps/skills/core/plannotator-review";
          plannotator-annotate = "${inputs.plannotator}/apps/skills/core/plannotator-annotate";
          plannotator-last = "${inputs.plannotator}/apps/skills/core/plannotator-last";
          tuicr = "${inputs.tuicr}/skills/tuicr";
        };

        # Global rules (loaded as project memory in every project). The bodies are
        # shared with omp — see modules/ai/_rules.nix.
        rules = lib.mapAttrs (_name: rule: rule.text) user.aiRules;
      };

      home.packages = [
        # plugin binaries invoked by the plugin's hooks (PreToolUse/PermissionRequest).
        (addax.omni pkgs).unified.llm-agents-nix.packages.claude-plugins
        claudeCerit
      ];

      programs.git.ignores = [
        ".claude/"
      ];
    };
}
