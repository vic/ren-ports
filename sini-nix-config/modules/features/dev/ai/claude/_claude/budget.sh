#!/usr/bin/env bash
set -uo pipefail
sub="$HOME/.headroom/subscription_state.json"
event="${1:-unknown}"

# ★★★ FIRING LOG — this is what separates "the hook NEVER FIRED" from "the hook
# FIRED AND REACHED NOBODY", and those are different defects with different fixes.
# The second is the silent one: SubagentStop fired correctly on every one of ten
# probe dispatches and delivered ZERO, and only its own logfile proved the
# difference. Without a line like this a delivery count of 0 is UNDECIDABLE, and
# an undecidable zero reads as a dead channel. One append per hook invocation.
# The gates are the den-ag-design orchestrator's law, so every hook firing is
# gated (see gated.sh). `manual` is the on-demand read and is never gated. The
# log sits BELOW the gate: this fires on every tool call in every session.
. "$HOME/.claude/gated.sh" 2>/dev/null || exit 0
[ "$event" = manual ] || gated || exit 0
printf '%s\t%s\n' "$(date -Is)" "$event" \
  >> "$HOME/.claude/budget-fires.log" 2>/dev/null || true
ctx=$(ctx_pct)

# utilization_pct ONLY: `used` and `limit` read 0 against a live percentage, so
# any limit-minus-used arithmetic reports a full window as exhausted.
five="?"; seven="?"; mins="?"; stale=""
if [ -s "$sub" ]; then
  vals=$(jq -r '[(.latest.five_hour.utilization_pct // "x"),
                 (.latest.seven_day.utilization_pct // "x"),
                 (.latest.five_hour.seconds_to_reset // 0)] | @tsv' "$sub" 2>/dev/null)
  five=$(printf '%s' "$vals" | cut -f1)
  seven=$(printf '%s' "$vals" | cut -f2)
  secs=$(printf '%s' "$vals" | cut -f3)
  case "$five$seven" in "" | *[!0-9.]*) five="?"; seven="?" ;; esac
  mins=$(awk -v s="${secs:-0}" 'BEGIN{ if (s+0>0) printf "%d", s/60; else printf "?" }')
  # The poller runs a measured ~17% error rate, so staleness is a state to name.
  age=$(( $(date +%s) - $(stat -c %Y "$sub" 2>/dev/null || echo 0) ))
  [ "$age" -gt 900 ] && stale=" STALE(${age}s)"
fi

# Thresholds are HERE because a hook has to decide; the rules they serve are in
# the bootstrap prompt. WEEKLY OUTRANKS CONTEXT: a session limit resumes cleanly,
# a weekly limit needs handoff and recovery, so it is evaluated last and wins.
#
# ★ EACH GATE NAMES ITS CONSTRAINT, NEVER A MOOD (HANDOFF-RULES.md rule 4:
# "vigilance is a procedure, not a mood"). The two closeout gates are DIFFERENT
# KINDS OF EVENT and must not read alike: ctx>=90 has a real deadline, because the
# window only shrinks and compaction is the cliff. 7d>=95 has none — 5% is hours
# of light single-agent work, or under an hour at 4x parallel Opus. Wording it as
# an emergency buys a rushed handoff in the one case where recovery is expensive
# and handoff QUALITY is the whole point.
# ★★★ THE 70 GATE BLOCKS FRESH SUBJECTS, NOT DELIVERY (owner-ruled 2026-09-01). It
# printed "NO NEW DISPATCH - in-flight only", which was read as a STOP-WORK signal
# with 30% of the window left: the fleet went idle and the session reported that
# nothing could be done rather than finishing what was open. 30% is ample to finish
# delivery AND write a clean handoff. The line is the SUBJECT, not the tool call —
# fix rounds, gate contacts, landings, banking and filing an already-measured
# finding all CONTINUE and are expected; only opening an untouched subject stops.
# Wording it as "no new dispatch" also made an idle fleet look like an empty queue,
# when a stream with an unlanded revision or an unbanked report is still open.
# ★★★ THRESHOLDS RAISED AND THE PURPOSE RESTATED — OWNER, 2026-09-02, verbatim:
# "we're good to go until >= 90% and start new work all the way up to 75%. The reason
# we monitor context is to ensure that we're able to provide a comprehensive and clean
# handoff." Three changes, and the third is the one that matters:
#   · 70 -> 75 for the fresh-subject line.
#   · The separate 85% PREPARE CLOSEOUT step RETIRES. Work continues to 90 and closeout
#     begins there; a middle rung that only says "get ready" spent a reading on nothing.
#   · THE GROUND OF THE 90 ROW CHANGES while its number does not. It is no longer
#     "compaction is the deadline" — it is that the remaining window IS the handoff.
#     The gates are HANDOFF PROTECTION, not an anti-compaction reflex: a session that
#     spends its last window writing a THIN handoff has failed the purpose even if it
#     never compacted, and one that compacts having already banked everything has lost
#     little. Judge a reading against the handoff you could still write, not the cliff.
# The same ruling: DO NOT REPORT THIS LINE TO THE OWNER. It is instrumentation for the
# orchestrator's own scheduling; narrating it upward spends his attention on a number he
# did not ask for. Law side: STATUS/RESUME-PROMPT-ARCH.md's budget section, amended in
# the same act with the old thresholds struck rather than deleted.
gate=""
if [ "$ctx" != "?" ]; then
  gate=$(awk -v c="$ctx" 'BEGIN{
    if (c+0 >= 90)      print "CLOSE OUT (ctx>=90) - the rest of the window is the handoff";
    else if (c+0 >= 75) print "NO FRESH SUBJECTS (ctx>=75) - finish open streams, start nothing new";
  }')
fi
if [ "$seven" != "?" ] && awk -v w="$seven" 'BEGIN{exit !(w+0>=95)}'; then
  gate="CLEAN CLOSEOUT (7d>=95) - unhurried; finish in-flight, no new dispatch"
fi

line=$(printf 'BUDGET %s · ctx %s%% · 5h %s%% (%sm) · 7d %s%%%s%s' \
  "$event" "$ctx" "$five" "$mins" "$seven" "$stale" "${gate:+ · GATE: $gate}")

# ★ DELIVERY DIFFERS BY EVENT, MEASURED 2026-09-01 (claude-code 2.1.246), and
# plain stdout reaches the model on SessionStart ONLY. Armed probe, 10 fires:
# a SubagentStop hook emitting `systemMessage` AND
# `hookSpecificOutput.additionalContext` produced ZERO deliveries — the event
# has no attachment record at all (control: SessionStart => 7). The same
# `additionalContext` shape on PreToolUse DID land. So this is not a schema
# problem on SubagentStop; that event cannot reach the model in any shape.
# ★ THE `hookSpecificOutput` ARM STAYS GENERALISED over event name rather than
# hardcoding PreToolUse: the shape is what the event family accepts, and threading
# `$event` costs nothing while letting a future wiring reuse it without editing the
# emitter. PostToolUse is NOT wired (see the hooks block: wrong beat, and the
# on-demand read supersedes it) — this arm simply does not refuse it.
# ★★ WHEN A DELIVERY COUNT IS 0, IT IS UNDECIDABLE UNTIL THE FIRING LOG IS READ.
# `~/.claude/budget-fires.log` gets one append per invocation, so "never fired" and
# "fired and reached nobody" are distinguishable — the distinction SubagentStop's
# ten-fire probe needed its own logfile to make. Count deliveries as records of
# type "attachment" in the session transcript, NEVER as a raw grep: the event name
# appears in this file and in any tool call that installs a probe.
# ★ OUTSIDE SessionStart AND Agent DISPATCHES THE LINE CARRIES ONLY A GATE CROSSING,
# once per event kind. PreToolUse and UserPromptSubmit both carry it because the
# orchestrator mostly wakes on task notifications and peer messages, and whether
# those fire UserPromptSubmit is unmeasured. The record is per event so one channel
# delivering into nothing cannot mute the other.
if [ "$event" != SessionStart ] && [ "$event" != manual ] && [ "$(hook_field .tool_name)" != Agent ]; then
  seen="$marker.gate.$event"
  if [ -z "$gate" ]; then rm -f "$seen"; exit 0; fi
  [ "$gate" != "$(cat "$seen" 2>/dev/null)" ] || exit 0
  printf '%s' "$gate" > "$seen"
fi
case "$event" in
  PreToolUse* | PostToolUse*)
    printf '%s' "$line" \
      | jq -Rs --arg ev "$event" '{hookSpecificOutput:{hookEventName:$ev,additionalContext:.}}'
    ;;
  *) printf '%s\n' "$line" ;;
esac
exit 0
          '';
