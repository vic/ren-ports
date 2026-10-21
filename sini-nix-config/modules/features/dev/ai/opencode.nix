# OpenCode (https://opencode.ai): terminal AI coding agent.
# Config is split: opencode-config.nix (opencode.json, tui.json), opencode-skills.nix (skills, subagents).
{ ren, inputs, ... }:
{
  ren.aspects.dev-ai-agents-opencode = {
    includes = with ren.aspects; [
      svc-ai-ninfer-client
      svc-ai-hyperqwen-client
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
        ];

        programs.git.ignores = [
          "/.opencode/"
        ];
      };

    persistHome = {
      directories = [
        ".config/opencode"
      ];
    };
  };
}
