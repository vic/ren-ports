# numtide/llm-agents.nix CLI tooling for coding agents (codegraph, playwright-mcp).
{ inputs, ... }:
{
  ren.aspects.dev-ai-llm-agents = {
    flake-inputs.llm-agents.url = "github:numtide/llm-agents.nix";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codegraph
          pkgs.playwright-mcp
        ];

        programs.git.ignores = [
          "/AGENTS.md"
          "/graphify-out/"
        ];
      };
  };
}
