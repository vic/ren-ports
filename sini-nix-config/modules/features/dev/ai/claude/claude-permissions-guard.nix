# settings.permissions ask + deny lists (allow list is in claude-permissions.nix).
{ ... }:
{
  ren.aspects.dev-ai-agents-claude.homeManager =
    { lib, ... }:
    {
      programs.claude-code.settings.permissions = {
        # Prompt even under an allow rule or auto mode, nested subcommands included.
        ask = [
          # Pattern kills have killed the orchestrator (pkill -f matched its own shell).
          "Bash(pkill *)"
          "Bash(killall *)"
          # Never stash in a shared checkout: peer sessions work in it.
          "Bash(git stash *)"
          # Deploys are the owner's.
          "Bash(colmena apply*)"
        ];

        # nix-config's generated files (its CLAUDE.md "Do Not Edit" list), in every
        # checkout and worktree of it. The repo gitignores .claude, so the rule lives here.
        deny =
          lib.concatMap
            (
              repo:
              map (p: "Edit(~/Documents/repos/sini/${repo}/${p})") [
                "flake.nix"
                "README.md"
                "TOPOLOGY.md"
                "diagrams/**"
                "generated/**"
                ".pre-commit-config.yaml"
                "charts/**/default.nix"
                "images/*/*/**"
              ]
            )
            [
              "nix-config*"
              "nix-darwin"
            ];
      };
    };
}
