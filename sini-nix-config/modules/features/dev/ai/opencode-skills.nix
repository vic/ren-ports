# OpenCode: collected agent-extensions deployed as skills and subagents.
{ ... }:
{
  ren.aspects.dev-ai-agents-opencode.homeManager =
    {
      lib,
      pkgs,
      agent-extensions ? { },
      ...
    }:
    let
      # agent-extensions is a LIST (one entry per contributing aspect): flatten and FOLD, never attr-select.
      extensionsList = lib.flatten agent-extensions;
      collectFrom = key: lib.foldl' (acc: e: acc // (e.${key} or { })) { } extensionsList;

      collectedSkills = collectFrom "skills";
      collectedAgents = collectFrom "agents";

      # Unwrap flake input attrsets to pure Nix store paths
      resolveSrc = src: src.outPath or src;

      skillFiles = lib.mapAttrs' (
        name: src:
        lib.nameValuePair ".config/opencode/skills/${name}" {
          source = resolveSrc src;
        }
      ) collectedSkills;

      # Subagents are written in Claude Code's frontmatter (`tools:` a list, `model: opus`), which opencode
      # rejects: it wants `tools` as an object and `model` as provider/model, and one bad agent fails the
      # whole config. Both keys are dropped, so opencode gives these agents its own default tools and model.
      opencodeAgent =
        name: src:
        pkgs.runCommand "opencode-agent-${name}.md" { } ''
          awk 'NR == 1 && $0 == "---" { fm = 1; print; next }
               fm && $0 == "---" { fm = 0 }
               fm && /^(tools|model):/ { next }
               { print }' ${resolveSrc src} > $out
        '';
      agentFiles = lib.mapAttrs' (
        name: src:
        lib.nameValuePair ".config/opencode/agent/${name}.md" {
          source = opencodeAgent name src;
        }
      ) collectedAgents;
    in
    {
      home.file = skillFiles // agentFiles;
    };
}
