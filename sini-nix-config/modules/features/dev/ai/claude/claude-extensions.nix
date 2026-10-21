# programs.claude-code: package + extension-derived skills/agents/commands/mcpServers, lspServers.
{ inputs, ... }:
{
  ren.aspects.dev-ai-agents-claude.homeManager =
    {
      agent-extensions,
      lib,
      pkgs,
      ...
    }:
    let
      extensionsList = lib.flatten agent-extensions;

      skillExts = lib.filter (e: e.type or "" == "skill" || e.type or "" == "mcp") extensionsList;
      mcpExts = lib.filter (e: e.type or "" == "mcp") extensionsList;

      claudeSkills = lib.foldl' (
        acc: e: if (e ? skills) then acc // (lib.mapAttrs (_: src: src.outPath or src) e.skills) else acc
      ) { } skillExts;

      claudeAgents = lib.foldl' (
        acc: e: if (e ? agents) then acc // e.agents else acc
      ) { } extensionsList;

      claudeCommands = lib.foldl' (
        acc: e: if (e ? commands) then acc // e.commands else acc
      ) { } extensionsList;

      # Two transports. A server declaring `url` is remote — claude-code
      # connects over HTTP and there is no process to spawn, so `command` is
      # absent and forcing type=stdio onto it produces an entry the client
      # cannot use. Everything else is a local process. Keyed on `url` rather
      # than an explicit flag so existing stdio aspects need no change.
      claudeMcpServers = lib.foldl' (
        acc: e:
        acc
        // (lib.mapAttrs (
          _name: server:
          if server ? url then
            {
              type = server.type or "http";
              inherit (server) url;
            }
            // lib.optionalAttrs (server ? headers) { inherit (server) headers; }
            # A bearer token from a file the server names: claude-code runs
            # headersHelper at connect time, so the token never enters the store.
            // lib.optionalAttrs (server ? bearerTokenFile) {
              headersHelper = "printf '{\"Authorization\":\"Bearer %s\"}' \"$(cat \"$HOME/${lib.removePrefix "~/" server.bearerTokenFile}\")\"";
            }
          else
            {
              type = "stdio";
              inherit (server) command;
              args = server.args or [ ];
              env = server.env or { };
            }
        ) (e.mcpServers or { }))
      ) { } mcpExts;
    in
    {
      programs.claude-code = {
        enable = true;
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
        enableMcpIntegration = true;
        mcpServers = claudeMcpServers;
        skills = claudeSkills;
        agents = claudeAgents;
        commands = claudeCommands;

        lspServers.nix = {
          command = lib.getExe pkgs.nil;
          extensionToLanguage.".nix" = "nix";
        };

        # Empty on purpose: the registry is written in claude-marketplaces.nix instead. This
        # option is typed `attrsOf (either package path)`, so every entry it can express is a
        # `directory` source — and CC reserves the name `claude-plugins-official` to GitHub
        # sources in the `anthropics` org, so the one entry that must be in that file is the
        # one entry this option cannot produce.
        marketplaces = { };
      };
    };
}
