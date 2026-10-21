# headroom (github:headroomlabs-ai/headroom): Context compression layer for AI agents.
# Ships a store-pinned plugin containing native startup and compression hooks,
# backed by a local proxy server and CLI binary (pkgs.local.headroom-ai).
# Linux service: headroom-service.nix; darwin agent: headroom-darwin.nix.
{ ... }:
{
  ren.aspects.dev-ai-mcp-headroom = {
    flake-inputs.headroom = {
      url = "github:headroomlabs-ai/headroom";
      flake = false;
    };
    agent-extensions =
      { lib, pkgs, ... }:
      {
        type = "mcp";
        mcpServers = {
          headroom = {
            command = "${lib.getExe pkgs.local.headroom-ai}";
            args = [
              "mcp"
              "serve"
            ];
          };
        };
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = [
          pkgs.local.headroom-ai
          pkgs.uv
        ];

        programs.claude-code = {
          # ★ THE PLUGIN IS NOT INSTALLED — it was a reference, and installing it was a
          # mistake (owner, 2026-09-02). Its hooks are `headroom init hook ensure` on
          # SessionStart and PreToolUse, and what that ENSURES is a self-heal hook written
          # into ~/.claude/settings.local.json with an ABSOLUTE STORE PATH baked in.
          #
          # That cannot work here. Measured 2026-09-02: the entry pinned
          # l9zgs4zw…-headroom-ai-0.36.5 while the live binary was
          # 8sf78ady…-headroom-ai-0.36.5 — SAME VERSION, different hash, because the
          # closure was rebuilt underneath it. So it breaks on ANY rebuild touching ANY
          # dependency, not on upgrades, and deleting the stale entry does not help: the
          # plugin rewrites it with the path of the day and it goes stale again.
          #
          # Nothing is lost. Compression runs through the proxy (ANTHROPIC_BASE_URL below)
          # and the MCP server above, both from pkgs.local.headroom-ai. The plugin's only
          # contribution was the hook that installs the broken hook.
          settings = {
            env = {
              ANTHROPIC_BASE_URL = "http://127.0.0.1:8787";
              HEADROOM_1M = "1";
            };
            permissions.allow = [
              "Bash(headroom *)"
            ];
          };
        };
      };

    # Message content and the CCR original-bytes store are regenerable scratch on a
    # separate dataset that is not backed up — deliberately NOT persistHome, since
    # both hold verbatim conversation content.
    cacheHome.directories = [
      ".headroom/logs"
      ".headroom/clients"
    ];
  };
}
