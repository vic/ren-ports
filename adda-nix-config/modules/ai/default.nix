# ai: umbrella (plannotator, tuicr) + claude/herdr/omp; ollama and voxtype are separate aspects
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.ai.homeManager = { pkgs, ... }: {
    home.packages = [
      # https://plannotator.ai/.
      (addax.omni pkgs).unified.llm-agents-nix.packages.plannotator
      # https://tuicr.dev/: agent-driven TUI review workflow.
      (addax.omni pkgs).unified.llm-agents-nix.packages.tuicr
    ];

    xdg.configFile."tuicr/config.toml".source = pkgs.writers.writeTOML "tuicr-config.toml" {
      theme = "dark";
      diff_view = "side-by-side"; # or "unified"
      ignore_whitespace = true; # ignore all whitespace in local VCS diffs
      appearance = "system"; # or "dark" / "light"
      mouse = true;
      leader = ";"; # configurable prefix for leader shortcuts
      comment_vim = true; # vim modal editing in the review comment box
      relative_line_numbers = false; # show rendered-row distances in the diff gutter
      # comment_types = {
      #   id = "issue";
      #   color = "red";
      #   definition = "must fix before merge";
      # };
    };
  };

  ren.aspects.ai.includes = with ren.aspects; [
    # ai._
    ai-claude
    ai-herdr
    ai-omp
    # ai-ollama
  ];
}
