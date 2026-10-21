# settings.json: general keys, env, and enabledPlugins (official + store-pinned extension plugins).
{ ... }:
{
  ren.aspects.dev-ai-agents-claude.homeManager =
    {
      agent-extensions,
      config,
      lib,
      ...
    }:
    let
      pluginExts = lib.filter (e: e.type or "" == "plugin") (lib.flatten agent-extensions);

      claudeEnabledPlugins = lib.foldl' (
        acc: e: acc // { ${e.marketplace.pluginId} = e.marketplace.enabled or true; }
      ) { } pluginExts;
    in
    {
      programs.claude-code.settings = {
        theme = "auto";
        verbose = true;
        effortLevel = "xhigh";
        remoteControlAtStartup = false;
        includeCoAuthoredBy = false;
        gitAttribution = false;
        attribution = {
          commit = "";
          pr = "";
        };

        #autoMemoryEnabled = false; # I copied this from someones config, need to figure out what their memory looks like...
        autoMemoryDirectory = "~/.claude/memory";

        teammateMode = "in-process";

        # CC compacts an idle session before the 1h prompt cache expires ("Compacted while
        # idle"), losing context we would rather keep. Auto-compact at the window edge stays on.
        idleCompaction = false;

        env = {
          CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";

          # The one supported way to give Bash tool shells a per-directory environment.
          # Measured in claude-code 2.1.229: the binary reads this path and prepends its
          # contents to the shell it spawns. The hooks keep the snapshot current. Without it,
          # agents inherit NOTHING from a devshell.
          CLAUDE_ENV_FILE = "${config.home.homeDirectory}/.claude/direnv-snapshot.sh";
          ENABLE_TOOL_SEARCH = "auto:5";

          # DISABLE_TELEMETRY also disables the GrowthBook feature-gate client; gate lookups
          # fall to compiled-in defaults before the on-disk cache in ~/.claude.json, so
          # telemetry-off silently removes gate-enabled features (e.g. Remote Control). This
          # flag is upstream's supported opt-out; ~/.claude.json is persisted (claude-state).
          # CLAUDE_CODE_GB_DISK_CACHE_WHEN_TELEMETRY_OFF = "1";
        };

        enabledPlugins = {
          # These four come from the official marketplace, which CC installs
          # and owns itself (see marketplaces in claude-extensions.nix). Everything else is
          # store-pinned and resolves from nix-store paths.
          "commit-commands@claude-plugins-official" = true;
          "skill-creator@claude-plugins-official" = true;
          "code-simplifier@claude-plugins-official" = true;
          "rust-analyzer-lsp@claude-plugins-official" = true;
        }
        // claudeEnabledPlugins;
      };
    };
}
