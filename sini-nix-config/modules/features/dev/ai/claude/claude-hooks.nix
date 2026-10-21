# settings.hooks. Scripts live in claude-scripts*.nix. `|| true` on all but the two that refuse by exit 2.
{ ... }:
{
  ren.aspects.dev-ai-agents-claude.homeManager =
    { config, ... }:
    let
      hook = cmd: {
        type = "command";
        command = "bash ${config.home.homeDirectory}/.claude/${cmd}";
      };
    in
    {
      programs.claude-code.settings.hooks = {
        SessionStart = [
          { hooks = [ (hook "load-direnv.sh || true") ]; }
          { hooks = [ (hook "budget.sh SessionStart || true") ]; }
          {
            matcher = "compact";
            hooks = [ (hook "handoff-commission.sh || true") ];
          }
        ];

        # Gated like budget.sh: the den-ag-design fleet's brief invariants, into each subagent.
        # SubagentStart reaches the SUBAGENT's context via `additionalContext` (documented).
        SubagentStart = [ { hooks = [ (hook "subagent-brief.sh || true") ]; } ];

        # Two events, deliberately: session start, and every directory change. NOT PreToolUse —
        # refreshing per tool call is the fork-bomb shape the upstream example warns about.
        # `|| true` so a direnv failure never blocks a session or a tool call.
        CwdChanged = [ { hooks = [ (hook "load-direnv.sh || true") ]; } ];

        # A subagent finished. Agents go idle WITHOUT delivering their report and the reflex is
        # to re-prompt; this makes the stop visible and names the correct next move.
        # The budget.sh SubagentStop call is RETIRED (measured 2026-09-01: delivers NOTHING to
        # the model); subagent-stop.sh is on the same dead channel and stays wired for its log.
        SubagentStop = [ { hooks = [ (hook "subagent-stop.sh || true") ]; } ];

        # The dispatch gate lives on PreToolUse (every tool; budget.sh speaks only on a gate
        # crossing for non-Agent tools). PostToolUse/Agent was withdrawn: the Agent tool returns
        # at spawn, so it duplicates the dispatch beat. budget.sh reads on demand instead:
        #   printf '{"transcript_path":"<session>.jsonl"}' | bash ~/.claude/budget.sh manual
        PreToolUse = [
          { hooks = [ (hook "budget.sh PreToolUse || true") ]; }
          # NO `|| true`: exit 2 is the refusal. Every session, not gated.
          {
            matcher = "Bash";
            hooks = [ (hook "bash-guard.sh") ];
          }
        ];

        # Plain stdout reaches the model here. Gate crossings only, as for PreToolUse.
        UserPromptSubmit = [ { hooks = [ (hook "budget.sh UserPromptSubmit || true") ]; } ];

        # TeammateIdle is DELIBERATELY NOT WIRED: coincident with SubagentStop, strict subset.

        # About to compact. Steers the summary and holds early auto compaction; see the
        # script. NO `|| true`: exit 2 is how it holds, and the script exits 0 otherwise.
        PreCompact = [ { hooks = [ (hook "pre-compact.sh") ]; } ];
      };
    };
}
