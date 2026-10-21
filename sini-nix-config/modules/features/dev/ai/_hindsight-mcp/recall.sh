#!/usr/bin/env bash
# Recall standing law relevant to a prompt. Reads the hook payload on
# stdin, emits recalled text on stdout for injection as context.
#
# Fails OPEN at every step: a memory service that is down must never
# block a session, so all failure paths exit 0 with no output and
# stderr is never allowed to leak into the agent's context.
set -uo pipefail
base="@endpoint@"
bank="@bank@"
# den-law gates reads and writes (kubernetes/services/ai/hindsight.nix):
# every bank call carries the user's token.
auth=(-H "Authorization: Bearer $(cat @tokenFile@ 2>/dev/null)")

# Preflight, cheapest first. Without these a cold or empty bank costs
# a full recall round-trip on every prompt and injects a header with
# nothing under it.
@curl@ -sS -m 5 -o /dev/null "$base/health" 2>/dev/null || exit 0
nodes=$(@curl@ "${auth[@]}" -sS -m 10 "$base/v1/default/banks/$bank/stats" 2>/dev/null \
  | @jq@ -r '.total_nodes // 0' 2>/dev/null) || exit 0
[ "${nodes:-0}" -gt 0 ] 2>/dev/null || exit 0

payload=$(cat 2>/dev/null || true)
# hooks-reference documents `prompt`, but some claude-code builds
# emit `user_prompt`; upstream's own hook accepts both, so do we.
prompt=$(printf '%s' "$payload" \
  | @jq@ -r '(.prompt // .user_prompt) // empty' 2>/dev/null || true)
# Sub-5-char prompts ("ok", "yes") carry no retrieval signal and
# would inject arbitrary law against a meaningless query.
[ "${#prompt}" -lt 5 ] && exit 0

# Two filters, both load-bearing for a LAW bank:
#   tags   — `archived` memories are retired records; serving them as
#            current policy is the failure that tag exists to prevent.
#   min_scores — a weak semantic match injected as "standing law" is
#            worse than injecting nothing, because the agent cannot
#            tell a 0.09 match from a 1.10 one once it is in context.
body=$(@jq@ -nc --arg q "$prompt" \
  '{query:$q, tags:["active"], tags_match:"any", budget:"low",
    min_scores:{reranker:0.5}}' 2>/dev/null) || exit 0

resp=$(@curl@ "${auth[@]}" -sS -m 60 -X POST \
  "$base/v1/default/banks/$bank/memories/recall" \
  -H 'Content-Type: application/json' -d "$body" 2>/dev/null) || exit 0

# Partition on fact type. A `world` fact is the owner's text as
# authored; an `observation` is the engine's synthesis OF that text.
# Both earn their place, they are NOT the same kind of claim, and so
# they never share a header — an observation printed under "Standing
# law" is a paraphrase wearing the primary's label, which is the one
# thing this bank exists to prevent.
#
# The cap is [0:20] on RESULTS. It used to be `head -20` on LINES,
# and memory bodies run to dozens of lines each, so a single long
# first hit consumed the whole budget and every later memory was
# dropped with nothing to say so.
out=$(printf '%s' "$resp" | @jq@ -r --arg bank "$bank" '
  (.results // [])[0:20] as $r
  | [$r[] | select(.type != "observation") | "- " + (.text // empty)] as $law
  | [$r[] | select(.type == "observation") | "- " + (.text // empty)] as $obs
  | (if ($law | length) > 0
     then ["## Standing law (recalled from \($bank))", ""] + $law
     else [] end)
    + (if ($obs | length) > 0
       then ["", "## Observed patterns (synthesised from this bank — NOT owner law)", ""] + $obs
       else [] end)
  | .[]
' 2>/dev/null)
[ -z "$out" ] && exit 0

printf '%s\n' "$out"
exit 0
