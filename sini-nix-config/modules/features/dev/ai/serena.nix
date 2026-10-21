# serena (github:oraios/serena, PyPI: serena-agent): Semantic code-navigation MCP server.
{ ... }:
{
  ren.aspects.dev-ai-mcp-serena = {
    agent-extensions =
      { lib, pkgs, ... }:
      {
        type = "mcp";
        mcpServers.serena = {
          command = "${lib.getExe pkgs.local.serena-agent}";
          args = [
            "start-mcp-server"
            "--project-from-cwd"
            "--context"
            "claude-code"
            "--open-web-dashboard"
            "False"
          ];
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.local.serena-agent ];
        programs.git.ignores = [ ".serena" ];
        programs.claude-code.settings.permissions.allow = [ "Bash(serena *)" ];
      };
  };
}
