# gen-agents rendering: tools/models per role and the head+shared+body+protocol composition.
{ ... }:
{
  ren.helpers.genAgent =
    pkgs: lib: role:
    let
      d = ./_assets/gen-agents;
      mcp = server: map (t: "mcp__plugin_hm_${server}__${t}");
      # Read, recall and bank-append only: no bank delete/clear/update, no directive
      # writes, no index deletion, no `reflect`. No serena editors: Edit carries every edit.
      mcpCommon =
        mcp "hindsight" [
          "recall"
          "sync_retain"
          "get_memory"
          "list_memories"
          "invalidate_memory"
        ]
        ++ mcp "codebase-memory" [
          "search_graph"
          "search_code"
          "get_code_snippet"
          "trace_path"
          "query_graph"
          "index_status"
        ];
      base = [
        "Read"
        "Grep"
        "Glob"
        "Bash"
        "Write"
        "SendMessage"
      ];
      tools = {
        scout = base ++ mcpCommon;
        gate = base ++ mcpCommon;
        spec = base ++ [ "Edit" ] ++ mcpCommon;
        build = base ++ [ "Edit" ] ++ mcpCommon;
      };
    in
    pkgs.writeText "gen-${role}.md" (
      builtins.replaceStrings
        [ "@TOOLS@" "@MODEL@" ]
        [ "[${lib.concatStringsSep ", " tools.${role}}]" "opus" ]
        (builtins.readFile "${d}/_${role}-head.md")
      + "\n"
      + builtins.readFile "${d}/_shared-measurement.md"
      + "\n"
      + builtins.readFile "${d}/_${role}-body.md"
      + "\n"
      + builtins.readFile "${d}/_shared-protocol.md"
    );
}
