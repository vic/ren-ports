# hindsight hooks: READ on prompt (opt-in), WRITE on session end (archiveHook, owner only).
# The SubagentStart arm is in hindsight-hooks-subagent.nix.
#
# Three arms, three gates, deliberately different: UserPromptSubmit is opt-in
# and OFF (a per-prompt cost on an unmet evidence bar), SessionEnd is opt-in
# and ON (the write path, with the evidence recorded at its option), and
# SubagentStart is UNCONDITIONAL — it is a read, it costs nothing against an
# empty bank, and an agent dispatched without its standing law is the failure
# this aspect exists to prevent.
#
# Hook LISTS merge across modules: codebase-memory.nix contributes its own
# SubagentStart command arm and the two combine rather than conflict. The path
# must be `hooks.SubagentStart`: a bare `SubagentStart` evaluates clean and
# silently drops all four.
{ lib, ... }:
{
  ren.aspects.dev-ai-mcp-hindsight.homeManager =
    { host, user, config, pkgs, ... }:
    let
      h = import ./_hindsight-mcp/lib.nix { inherit lib pkgs host user config; };
    in
    {
      programs.claude-code.settings = lib.mkMerge [
        (lib.mkIf h.cfg.recallHook {
          hooks.UserPromptSubmit = [
            { hooks = [ { type = "command"; command = "bash ${h.recall} || true"; } ]; }
          ];
        })
        (lib.mkIf (h.cfg.archiveHook && h.writer) {
          hooks.SessionEnd = [
            {
              hooks = [
                {
                  type = "command";
                  # Rendering is local and cheap; the retain is `async: true`, so
                  # the request returns once accepted rather than once extracted.
                  command = "bash ${h.archive} || true";
                  timeout = 60;
                }
              ];
            }
          ];
        })
      ];
    };
}
