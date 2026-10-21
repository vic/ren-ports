# searxng MCP: the fleet's SearXNG as a search tool for every harness that takes
# MCP servers through agent-extensions. Server: nixpkgs `mcp-searxng`. Only the first
# three tools are pre-allowed in claude; web_url_read stays on the harness prompt.
# pi is not covered (takes TypeScript extensions). Gating check: searxng-check.nix.
{ ren, lib, ... }:
{
  # settings.endpoint
  ren.kinds.machine.dev-ai-mcp-searxng = ren.lib.opt (lib.types.submodule {
    options.endpoint = lib.mkOption {
      type = lib.types.str;
      default = "http://10.11.0.24:8080";
      description = ''
        Base URL of the fleet's SearXNG. Defaults to the axon cluster's
        `searxng-internal` LoadBalancer address, BGP-advertised to the LAN and not
        internet-routable; search.<domain> is the OIDC-gated UI, which a headless
        client cannot pass.
      '';
    };
  }) { };

  ren.aspects.dev-ai-mcp-searxng = {
    agent-extensions =
      {
        host,
        lib,
        pkgs,
        ...
      }:
      {
        type = "mcp";
        mcpServers.searxng = {
          command = lib.getExe pkgs.mcp-searxng;
          env.SEARXNG_URL = host.dev-ai-mcp-searxng.endpoint;
        };
      };

    homeManager.programs.claude-code.settings.permissions.allow = map (t: "mcp__plugin_hm_searxng__${t}") [
      "searxng_web_search"
      "searxng_search_suggestions"
      "searxng_instance_info"
    ];
  };
}
