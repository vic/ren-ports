# hindsight: remote MCP entry (url + bearer token file) and its skill. See hindsight.nix.
{ ... }:
{
  ren.aspects.dev-ai-mcp-hindsight.agent-extensions =
    { host, lib, pkgs, ... }:
    let
      cfg = host.dev-ai-mcp-hindsight;
      url = "${cfg.endpoint}/mcp/${cfg.bank}/";
      bearerTokenFile = "~/.config/hindsight/den-law-token";
    in
    {
      type = "mcp";
      mcpServers.hindsight = {
        # Trailing slash matters: upstream serves the per-bank endpoint at
        # `/mcp/<bank>/` and a request without it does not route.
        inherit url;
        # Read by each agent's renderer into its own header mechanism
        # (claude.nix headersHelper, opencode.nix {file:}); never in the store.
        inherit bearerTokenFile;
        # For an agent that cannot set headers (agy sends them verbatim): a stdio
        # bridge that reads the token at spawn. It travels in mcp-proxy's
        # API_ACCESS_TOKEN, not argv, so it stays out of /proc/<pid>/cmdline.
        stdio.command = "${pkgs.writeShellScript "hindsight-mcp-bridge" ''
          API_ACCESS_TOKEN=$(cat "$HOME/${lib.removePrefix "~/" bearerTokenFile}")
          export API_ACCESS_TOKEN
          exec ${lib.getExe pkgs.mcp-proxy} --log-level WARNING --transport streamablehttp ${lib.escapeShellArg url}
        ''}";
      };
      skills.hindsight = ./_hindsight-mcp/skill;
    };
}
