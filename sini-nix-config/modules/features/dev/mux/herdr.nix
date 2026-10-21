{ inputs, ... }:
{
  ren.aspects.dev-mux-herdr.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr ];

      # Source the Claude Code skill straight from the herdr package's own
      # source tree (upstream ships SKILL.md at its root) rather than vendoring
      # a copy in-repo. Inert unless the claude aspect enables programs.claude-code.

      # TODO: Restore at next touch
      # programs.claude-code.skills.herdr = "${inputs'.llm-agents.packages.herdr.src}/SKILL.md";
    };
}
