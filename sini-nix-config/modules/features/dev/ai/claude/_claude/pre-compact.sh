#!/usr/bin/env bash
set -uo pipefail
. "$HOME/.claude/gated.sh" 2>/dev/null || exit 0
gated || exit 0

# ★ AUTO BELOW THE 90 GATE IS HELD. Measured: every auto boundary in the
# orchestrator's transcripts was IDLE compaction, firing ~50 min after an
# away_summary at 22–77% of the window, never the threshold. Holding it costs a
# cold cache; letting it through costs the context the 90 gate exists to spend on
# the handoff. Manual (the owner's choice), >=90 and an unreadable ctx all pass.
# ★ THE ESCAPE IS FOR A MISREAD DIVISOR (a mid-session switch to a 200K model, which
# the marker does not track), and it must never wedge the hard limit. An auto attempt
# after a hold passes when the window GREW within 15 minutes, which is a threshold
# retry turn after turn, or when it came within 60s, which is a reactive compact
# following its failed request. An idle retry adds no tokens, so it is held again.
# Every decision is logged: a hold that leaks is otherwise invisible.
trigger=$(hook_field .trigger)
tok=$(ctx_tokens)
ctx=$(ctx_pct "$tok")
decide() {
  [ "$trigger" = auto ] || { echo "pass:$trigger"; return; }
  [ "$ctx" != "?" ] || { echo "pass:no-ctx"; return; }
  awk -v c="$ctx" 'BEGIN{exit !(c+0 < 90)}' || { echo "pass:gate"; return; }
  local now prev_at prev_tok
  now=$(date +%s)
  read -r prev_at prev_tok 2>/dev/null < "$marker.held" || prev_at=0
  if [ $((now - prev_at)) -lt 60 ]; then echo "pass:reactive"; return; fi
  if [ $((now - prev_at)) -lt 900 ] && [ "$tok" -gt "${prev_tok:-0}" ]; then
    echo "pass:grown"
    return
  fi
  echo "$now $tok" > "$marker.held"
  echo hold
}
decision=$(decide)
printf '%s\t%s\t%s\tctx=%s\ttok=%s\t%s\n' "$(date -Is)" "$sid" "$trigger" "$ctx" "$tok" "$decision" \
  >> "$HOME/.claude/precompact-decisions.log" 2>/dev/null || true
if [ "$decision" = hold ]; then
  echo "auto compaction held at ctx $ctx%: below the 90% close-out gate" >&2
  exit 2
fi

cat <<'MSG'
SUMMARY INSTRUCTIONS — den-ag-design orchestrator. Carry these VERBATIM, never paraphrased:
  · every live agent: name/id, its task, and the artefact it was told to write
  · every owner ruling, fork or residue NOT yet banked in a bead body, with its bead id
  · in-flight bead ids with their state, and the repo state measured below
End the summary with the resume path: read STATUS/RESUME-PROMPT-ARCH.md, then
STATUS/HANDOFF.md, then reconcile both against the bead graph before acting.

MSG
echo "Measured at the boundary (ctx $ctx%):"
if command -v br >/dev/null 2>&1; then
  n=$(br list --status in_progress --limit 0 2>/dev/null | grep -c "" || echo "?")
  echo "  in_progress rows      : $n   (a status nobody stands behind is a claim with no writer)"
  br sync --status 2>/dev/null | grep -i dirty | sed "s/^/  export /" || true
else
  echo "  tracker               : br not on PATH here"
fi
for r in "$HOME"/Documents/repos/sini/den-ag-design "$HOME"/Documents/repos/sini/gen*; do
  [ -d "$r/.git" ] || continue
  st=$(git -C "$r" status --porcelain 2>/dev/null | wc -l)
  ah=$(git -C "$r" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
  [ "$st" -gt 0 ] || [ "$ah" -gt 0 ] && printf "  %-22s %s modified, %s unpushed\n" "$(basename "$r")" "$st" "$ah"
done
exit 0
          '';
