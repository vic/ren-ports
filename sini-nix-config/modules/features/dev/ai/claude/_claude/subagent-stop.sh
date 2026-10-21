#!/usr/bin/env bash
set -uo pipefail
log="$HOME/.claude/subagent-stops.log"
mkdir -p "$(dirname "$log")"
printf '%s\tstopped\n' "$(date -Is)" >> "$log" 2>/dev/null || true
. "$HOME/.claude/gated.sh" 2>/dev/null || exit 0
gated || exit 0
cat <<'MSG'
A subagent just STOPPED.

If its report has NOT arrived: TREE FIRST, then prompt ONCE. Never re-dispatch — a
resend duplicates completed work, while a message revives the agent with its context.
Read the artefact it was told to write before assuming nothing happened: reports
routinely cross the idle notification.

A silent idle is NOT a clean result. Never infer a finding, a pass, or an absence from
a report that never arrived — say it is outstanding.

An attempt that failed and wrote NOTHING looks identical from here to work never
started. If the tree is unchanged, that is "no artefact", never "no attempt".
MSG
exit 0
