# codebase-memory claude-code hooks: grep/glob augmenter, session + subagent reminders.
# Same aspect as codebase-memory.nix. Reminder prose is in _codebase-memory-reminder.txt.
{ inputs, ... }:
{
  ren.aspects.dev-ai-mcp-codebase-memory.homeManager =
    { pkgs, lib, ... }:
    let
      cbm = inputs.codebase-memory-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default;
      sessionReminder = pkgs.writeShellScript "cbm-session-reminder" "cat ${./_codebase-memory-reminder.txt}";
      # The context is prose, so both escapings are derived and never
      # hand-written: `toJSON` owns the quoting inside the payload and
      # `escapeShellArg` owns the quoting around it. A hand-quoted payload
      # only has to contain one apostrophe (`get_architecture's`) to close
      # the shell string and leave the remainder as bare tokens.
      subagentContext = "Code discovery: prefer codebase-memory-mcp tools (search_graph, trace_path, get_code_snippet, query_graph, search_code) over grep for languages the index covers. Nix IS covered for defs and calls (the function-headed-file gap is fixed). TWO TRAPS: (a) get_architecture's languages field does NOT list Nix even when thousands of Nix functions are indexed - confirm coverage with a known-positive symbol query, never that field; (b) CALLS edges MISS attrset-mediated calls (stagedResolution.runPrePass), so ZERO CALLERS IS NOT EVIDENCE OF DEAD CODE - cross-check with Grep before concluding or deleting. Strong for structure, not trustworthy alone for reachability. Nix still yields no Variable nodes and no cross-repo edges. The nix LSP (documentSymbol, hover, file-local goToDefinition) complements it. Never pass mode to index_repository - the default (full) walks everything, while fast/moderate silently skip directories named gen, media, docs, examples, scripts, tools, bin, build. Use Grep/Glob/Read for text, configs, and non-code files.";

      subagentReminder = pkgs.writeShellScript "cbm-subagent-reminder" ''
        printf '%s\n' ${
          lib.escapeShellArg (
            builtins.toJSON {
              hookSpecificOutput = {
                hookEventName = "SubagentStart";
                additionalContext = subagentContext;
              };
            }
          )
        }
      '';

      hookOf = command: [ { hooks = [ { type = "command"; inherit command; } ]; } ];
    in
    {
      # stdio MCP server: spawned per session by Claude Code, no daemon
      # needed. The per-repo SQLite index lives in ~/.cache and is shared
      # across sessions; incremental git-sync runs inside the server.
      programs.claude-code.settings.hooks = {
        PreToolUse = [
          {
            matcher = "Grep|Glob";
            hooks = [
              {
                type = "command";
                command = pkgs.writeShellScript "cbm-search-augmenter" ''
                  ${cbm}/bin/codebase-memory-mcp hook-augment 2>/dev/null
                  exit 0
                '';
              }
            ];
          }
        ];
        SessionStart = hookOf "${sessionReminder}";
        SubagentStart = hookOf "${subagentReminder}";
      };
    };
}
