# pi-coding-agent (https://pi.dev, github:earendil-works/pi-mono):
# Terminal AI coding agent with Stylix theme generation & Plan Mode extensions.
# Split: pi-theme.nix (stylix theme), pi-models.nix (models.json, auth.json, omp models.yml).
{ ren, inputs, ... }:
{
  ren.aspects.dev-ai-agents-pi = {
    includes = with ren.aspects; [
      svc-ai-ninfer-client
      svc-ai-hyperqwen-client
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.pi-coding-agent
          # oh-my-pi (github:can1357/oh-my-pi): a pi fork, as a tool beside pi. Its first
          # start writes a native addon into ~/.omp, and it contacts external hosts at
          # every start.
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp
        ];

        programs.git.ignores = [
          "/.pi/"
        ];

        home.sessionVariables = {
          OLLAMA_HOST = "http://10.9.2.2:11434";
        };

        # Deploy Plan Mode & Security Guard extensions for pi
        home.file.".pi/agent/extensions/plan-mode.ts".source = ./_pi/extensions/plan-mode.ts;
        home.file.".pi/agent/extensions/plan-tracker.ts".source = ./_pi/extensions/plan-tracker.ts;
        home.file.".pi/agent/extensions/security-guard.ts".source = ./_pi/extensions/security-guard.ts;

        # pi runs a small local model with no memory: what it needs to know about this
        # environment is deployed as a skill (loaded on demand) plus a short global
        # context file (always loaded), never left for it to discover by probing.
        home.file.".pi/agent/skills/matrix".source =
          inputs.matrix-xmsg.packages.${pkgs.stdenv.hostPlatform.system}.matrix-skill;
        home.file.".pi/agent/AGENTS.md".text = ''
          # Environment

          - This machine runs NixOS. The system is declared in ~/Documents/repos/sini/nix-config. The owner reviews and deploys every change to it;
            never apply, deploy or push it yourself.
          - Other agent sessions (Claude Code, Antigravity, pi) may be running on this host.
            Messages from them arrive with an "[xmsg]" header line. The `xmsg` skill explains how
            to reply, list sessions and send.
          - nix-config devshell: run `nix develop` in the repo, then `menu` to list its commands
            (for example list-infra, nix-flake-build, fmt).
          - Other hosts: use the `<host>.ts.json64.dev` names over ssh. The short aliases do not
            reach the machines.
        '';

        # Configure default settings to use stylix theme and local endpoints
        home.file.".pi/agent/settings.json".text = builtins.toJSON {
          # hyperqwen is the resident engine on the inference guest (owner,
          # 2026-10-10); ninfer and llama-cpp stay configured as standbys.
          defaultProvider = "hyperqwen";
          defaultModel = "qwen3.8-27b";
          defaultThinkingLevel = "medium";
          defaultProjectTrust = "never";
          theme = "stylix";
          extensions = [
            "~/.pi/agent/extensions/plan-mode.ts"
            "~/.pi/agent/extensions/plan-tracker.ts"
            "~/.pi/agent/extensions/security-guard.ts"
          ];
        };
      };

    persistHome = {
      directories = [
        ".pi"
      ];
    };
  };
}
