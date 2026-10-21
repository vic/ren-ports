# hunk (upstream: github:modem-dev/hunk): terminal diff viewer for reviewing agent changes.
{ inputs, ... }:
{
  ren.aspects.dev-ai-tools-hunk = {
    agent-extensions =
      { pkgs, ... }:
      {
        type = "skill";
        skills.hunk-review = "${inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hunk.src}/packages/hunk/skills/hunk-review";
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hunk ];
      };
  };
}
