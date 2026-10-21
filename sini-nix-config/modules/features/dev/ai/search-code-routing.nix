# search-code-routing: Structural code search routing across `ast-grep` (AST tree shape)
# and `ripgrep` (literal regex).
{ ... }:
{
  ren.aspects.dev-ai-skills-search-code-routing = {
    agent-extensions = {
      type = "skill";
      skills.search-code-routing = ./_assets/search-code-routing;
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.ast-grep
          pkgs.ripgrep
        ];
      };
  };
}
