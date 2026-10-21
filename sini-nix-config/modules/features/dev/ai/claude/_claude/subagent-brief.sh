#!/usr/bin/env bash
# SubagentStart: the brief invariants every den-ag-design dispatch must carry, injected into the subagent.
set -uo pipefail
. "$HOME/.claude/gated.sh" 2>/dev/null || exit 0
gated || exit 0
jq -nc --arg c "Brief invariants (den-ag-design fleet): Write your report as a file, and deliver it through SubagentHandback if your tools include it, otherwise SendMessage to the orchestrator. Write scratch only under <scratchpad>/<agent-name>-private/. Never pkill -f, killall, or kill on pgrep -f output; kill only a PID captured with \$!. Wait on a \$! PID or a producer-written marker, always under timeout, never pgrep -f from the waiting shell. Take STATUS/heavy-lock.zsh once per heavy phase, never per command. Run every nix eval/build/check under systemd-run --user --scope -q -p MemoryMax=12G; rc 137 under the cap is a finding." \
  '{hookSpecificOutput: {hookEventName: "SubagentStart", additionalContext: $c}}'
          '';
