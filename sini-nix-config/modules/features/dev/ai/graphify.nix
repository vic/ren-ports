# graphify (github:Graphify-Labs/graphify): Turn any folder of code, docs,
# papers, images, or videos into a queryable knowledge graph.
{ ren, inputs, ... }:
{
  ren.aspects.dev-ai-mcp-graphify = {
    flake-inputs.graphify = {
      url = "github:Graphify-Labs/graphify";
      flake = false;
    };

    agent-extensions =
      { pkgs, ... }:
      {
        type = "mcp";
        mcpServers.graphify.command = "${ren.helpers.graphifyPkg pkgs inputs.graphify}/bin/graphify-mcp";
        skills.graphify = "${inputs.graphify}/graphify";
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ (ren.helpers.graphifyPkg pkgs inputs.graphify) ];
        programs.claude-code.settings.permissions.allow = [
          "Bash(graphify *)"
          "Bash(graphify-mcp *)"
        ];
        programs.git.ignores = [
          "/graphify-out/"
          ".graphifyignore"
        ];
      };
  };

  # den duplicated this derivation inline in two let-bindings; one helper instead.
  ren.helpers.graphifyPkg =
    pkgs: src:
    pkgs.python3Packages.buildPythonApplication {
      pname = "graphifyy";
      version = "0.9.49";
      inherit src;
      format = "pyproject";
      nativeBuildInputs = [ pkgs.python3Packages.setuptools ];
      propagatedBuildInputs = with pkgs.python3Packages; [
        networkx
        numpy
        rapidfuzz
        tree-sitter
        mcp
        starlette
      ];
      dontCheckRuntimeDeps = true;
      doCheck = false;
    };
}
