# searxng-check: each harness's rendered config carries the searxng MCP entry (mcp/searxng.nix),
# read with jq from the files home-manager writes, on every host with roles.dev. Failing properties print by name.
#   nix build .#checks.x86_64-linux.searxng-harnesses
# A check of realized config is a class `into` reading `outputs` (README stratum 3; template features/headless.nix);
# content is data: the host names to check.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # nixpkgs evalModules/types for class content (fleet lib is ren.genLib)
in
{
  ren.classes.searxngCheck = {
    at = ren.kinds.system;
    into =
      { system, outputs, ... }:
      ms:
      let
        pkgs = system.legacyPackages;
        cfg =
          (lib.evalModules {
            modules = ms ++ [
              { options.hosts = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; }; }
            ];
          }).config;
        homeOf = h: outputs.nixosConfigurations.${h}.config.home-manager.users.sini;
        fileOf = h: name: (homeOf h).home.file.${name}.source;
        endpoint = "http://10.11.0.24:8080";
        allowed = [
          "mcp__plugin_hm_searxng__searxng_web_search"
          "mcp__plugin_hm_searxng__searxng_search_suggestions"
          "mcp__plugin_hm_searxng__searxng_instance_info"
        ];
        # name, rendered file, jq predicate that must print `true`.
        cells = lib.concatMap (h: [
          {
            # home-manager carries claude's servers in its generated `hm` plugin, the
            # namespace of the mcp__plugin_hm_<server>__ tool names allowed below.
            name = "${h}: claude declares the searxng server against the fleet endpoint";
            file = "${fileOf h "${(homeOf h).home.homeDirectory}/.claude/skills/claude-code-home-manager"}/.mcp.json";
            jq = ''.mcpServers.searxng.env.SEARXNG_URL == "${endpoint}"'';
          }
          {
            name = "${h}: claude pre-allows exactly the three search tools";
            file = fileOf h "${(homeOf h).home.homeDirectory}/.claude/settings.json";
            jq = ''([.permissions.allow[] | select(startswith("mcp__plugin_hm_searxng__"))] | sort) == (${builtins.toJSON allowed} | sort)'';
          }
          {
            name = "${h}: agy declares the searxng server";
            file = fileOf h ".gemini/config/mcp_config.json";
            jq = ''.mcpServers.searxng.env.SEARXNG_URL == "${endpoint}"'';
          }
          {
            name = "${h}: opencode declares the searxng server";
            file = fileOf h ".config/opencode/opencode.json";
            jq = ''.mcp.searxng.type == "local" and .mcp.searxng.environment.SEARXNG_URL == "${endpoint}"'';
          }
        ]) cfg.hosts;
      in
      {
        checks.drvs.searxng-harnesses = pkgs.runCommand "searxng-harnesses" { nativeBuildInputs = [ pkgs.jq ]; } ''
          failed=""
          ${lib.concatMapStrings (c: ''
            if [ "$(jq -r ${lib.escapeShellArg c.jq} ${c.file})" != true ]; then
              failed="$failed
            ${c.name}"
            fi
          '') cells}
          if [ -n "$failed" ]; then
            printf 'searxng-harnesses: failed:%s\n' "$failed" >&2
            exit 1
          fi
          echo "searxng-harnesses: ${toString (lib.length cells)} properties hold"
          touch $out
        '';
      };
  };

  ren.aspects.dev-ai-searxng-check = {
    at = ren.system.x86_64-linux;
    searxngCheck.hosts = [
      "bitstream"
      "blade"
      "cortex"
    ];
  };
}
