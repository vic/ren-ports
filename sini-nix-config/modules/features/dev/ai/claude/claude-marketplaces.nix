# CC's marketplace registry, written whole so home-manager is its only writer.
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
      pluginExts = lib.filter (e: e.type or "" == "plugin") (lib.flatten agent-extensions);

      claudeMarketplaces = lib.foldl' (
        acc: e: acc // { ${e.marketplace.name} = e.marketplace.src; }
      ) { } pluginExts;
    in
    {
      # The module's `marketplaces` option could not produce the official entry; CC appended
      # it itself and replaced HM's symlink with a plain file, which broke the next HM
      # activation. `autoUpdate = false` on every entry holds it (CC defaults the reserved
      # `claude-plugins-official` name to true and would rewrite the file at startup).
      # The official entry declares the GitHub source it really is (CC validates the reserved
      # name against its source) while `installLocation` reads the pinned input: no clone.
      home.file.".claude/plugins/known_marketplaces.json".source =
        (pkgs.formats.json { }).generate "claude-code-known-marketplaces.json"
          (
            lib.mapAttrs (_: src: {
              source = {
                source = "directory";
                path = "${src}";
              };
              installLocation = "${src}";
              lastUpdated = "1970-01-01T00:00:00Z";
              autoUpdate = false;
            }) claudeMarketplaces
            // {
              claude-plugins-official = {
                source = {
                  source = "github";
                  repo = "anthropics/claude-plugins-official";
                };
                installLocation = "${inputs.claude-plugins-official}";
                lastUpdated = "1970-01-01T00:00:00Z";
                autoUpdate = false;
              };
            }
          );
    };
}
