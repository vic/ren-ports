# Gemini / Antigravity agent harness: antigravity-cli (agy), gemini-cli, openskills.
# Manages the ~/.gemini customization tree, MCP server registry, and persistence.
{ inputs, ... }:
{
  ren.aspects.dev-ai-agents-antigravity-cli = {
    homeManager =
      {
        agent-extensions,
        config,
        lib,
        pkgs,
        ...
      }:
      let
        extensionsList = lib.flatten agent-extensions;
        llm = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

        allSkillSources = lib.foldl' (
          acc: e: if (e ? skills) then acc // (lib.mapAttrs (_: src: src.outPath or src) e.skills) else acc
        ) { } extensionsList;
        skillFiles = lib.mapAttrs' (
          name: source: lib.nameValuePair ".gemini/config/skills/${name}" { inherit source; }
        ) allSkillSources;

        allAgentSources = lib.foldl' (acc: e: if (e ? agents) then acc // e.agents else acc) { } extensionsList;
        agentFiles = lib.mapAttrs' (
          name: source: lib.nameValuePair ".gemini/config/agents/${name}.md" { inherit source; }
        ) allAgentSources;

        allCommandSources = lib.foldl' (acc: e: if (e ? commands) then acc // e.commands else acc) { } extensionsList;
        commandFiles = lib.mapAttrs' (
          name: source: lib.nameValuePair ".gemini/config/commands/${name}.md" { inherit source; }
        ) allCommandSources;

        mcpExts = lib.filter (e: e.type or "" == "mcp") extensionsList;
        # agy sends MCP headers verbatim, so a server that needs one declares a `stdio` fallback.
        allMcpServers = lib.mapAttrs (_: s: s.stdio or s) (
          lib.foldl' (acc: e: acc // (e.mcpServers or { })) { } mcpExts
        );
      in
      {
        home.packages = [
          llm.gemini-cli
          llm.skills
        ];

        # No `settings`: HM would make a read-only settings.json that blocks OAuth token writes
        # (nix-community/home-manager#8654).
        programs.antigravity-cli = {
          enable = true;
          package = llm.antigravity-cli;
          skills = allSkillSources;
          mcpServers = allMcpServers;
          commands = allCommandSources;
        };

        home.sessionVariables = {
          GEMINI_CONFIG_DIR = "${config.home.homeDirectory}/.gemini/config";
          ANTIGRAVITY_CONFIG_DIR = "${config.home.homeDirectory}/.gemini/config";
        };

        programs.git.ignores = [ "/.gemini/" ];

        home.file =
          skillFiles
          // agentFiles
          // commandFiles
          // {
            ".gemini/config/skills/.keep".text = "";
            ".gemini/config/rules/.keep".text = "";
          };
      };

    persistHome.directories = [
      ".gemini"
      ".config/antigravity-cli"
      ".config/gemini"
    ];
  };
}
