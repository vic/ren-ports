# claude-code config: a read-only declarative settings.json (seeded from cortex's
# canonical ~/.claude/settings.json) and the four-bucket ~/.claude state map that
# replaces the old blanket `persistHome [".claude"]`. Split by concern across claude-*.nix.
{ inputs, ... }:
{
  ren.aspects.dev-ai-agents-claude = {
    # Claude Code plugin marketplaces, store-pinned: CC resolves plugins from these
    # nix-store paths instead of fetching from GitHub at runtime (consistent with the
    # read-only settings.json). Plugin *enablement* lives in settings.enabledPlugins.
    # The built-in official marketplace, store-pinned: it backs the `installLocation` of
    # the `claude-plugins-official` entry in the generated registry, so the four
    # official plugins resolve from the store instead of a network clone.
    flake-inputs.claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official";
      flake = false;
    };

    homeLinux =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.socat
          pkgs.bubblewrap
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.crush
          pkgs.nodejs_22
          # pkgs.markitdown
        ];

        # Don't track ~/.claude in any repo.
        programs.git.ignores = [
          ".claude"
        ];
      };
  };
}
