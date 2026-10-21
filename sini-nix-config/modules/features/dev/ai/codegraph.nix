# codegraph (github:colbymchenry/codegraph): Semantic code intelligence and
# fast 100% local code graph for AI coding agents. Package comes from llm-agents.nix.
{ inputs, ... }:
{
  ren.aspects.dev-ai-mcp-codegraph = {
    agent-extensions =
      { pkgs, ... }:
      {
        type = "mcp";
        mcpServers.codegraph = {
          command = "${inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codegraph}/bin/codegraph";
          args = [
            "serve"
            "--mcp"
          ];
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codegraph ];
        programs.claude-code.settings.permissions.allow = [ "Bash(codegraph *)" ];
        programs.git.ignores = [ ".codegraph" ];
      };
  };
}
