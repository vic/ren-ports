set -uo pipefail
base="@endpoint@"
bank="@bank@"
# den-law gates reads and writes (kubernetes/services/ai/hindsight.nix):
# every bank call carries the user's token.
auth=(-H "Authorization: Bearer $(cat @tokenFile@ 2>/dev/null)")
inputs=@inputs@
log="$HOME/.claude/hindsight-subagent.log"
# Fails OPEN — exit 0, nothing on stdout — but every firing leaves one line.
note() { printf '%s\t%s\t%s\t%s\t%s\n' "$(date -Is)" "${agent:-?}" "${role:-?}" "$1" "id=${id:-?}" >> "$log"; exit 0; }

payload=$(cat 2>/dev/null || true)
agent=$(printf '%s' "$payload" | @jq@ -r '.agent_type // empty' 2>/dev/null)
id=$(printf '%s' "$payload" | @jq@ -r '.agent_id // empty' 2>/dev/null)
tp=$(printf '%s' "$payload" | @jq@ -r '.transcript_path // empty' 2>/dev/null)

# The role of a named teammate is read from the team registry, which Claude Code
# writes (`members[].agentType`) BEFORE the teammate spawns, so it cannot race the
# hook. The sidecar `agent-a<name>-<hex>.meta.json` (`customAgentType`) is written
# ~0.1-6.7s after the teammate joins (median 5.1s, n=39) — about the length of the
# poll below, so the poll alone lost the race for most first firings. The sidecar
# stays as a bounded fallback (matched by NAME; the payload's `agent_id` does not
# reliably name the file) for dispatches the registry does not list, and a miss is
# logged `from=timeout`, never blocked on.
# ponytail: the registry and `customAgentType` are claude-code's undocumented
# files; if both move, role falls back to agent_type and the log records
# `from=timeout` or `from=payload`.
role="" from=payload meta=""
if [ -n "$agent" ]; then
  role=$(@jq@ -rs --arg n "$agent" '[.[].members[]? | select(.name == $n)] | max_by(.joinedAt) | .agentType // empty' \
    "$HOME"/.claude/teams/*/config.json 2>/dev/null)
  [ -n "$role" ] && from=config
fi
# An unnamed `subagent_type` dispatch already carries its role in agent_type.
if [ -z "$role" ] && [ -n "$agent" ] && [ "${agent#gen-}" = "$agent" ]; then
  from=timeout
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    meta=$([ -d "${tp%.jsonl}/subagents" ] && find "${tp%.jsonl}/subagents" -name "agent-*$agent*.meta.json" -printf '%T@ %p\n' 2>/dev/null \
      | sort -rn | cut -d' ' -f2- | while IFS= read -r f; do
        [ "$(@jq@ -r '.agentType // .name // empty' "$f" 2>/dev/null)" = "$agent" ] && { printf '%s' "$f"; break; }
      done)
    [ -n "$meta" ] && { from=payload; break; }
    sleep 0.5
  done
  [ -n "$meta" ] && role=$(@jq@ -r '.customAgentType // empty' "$meta" 2>/dev/null)
  [ -n "$role" ] && from=sidecar
fi
[ -n "$role" ] || role="$agent"

input=$(printf '%s' "$inputs" | @jq@ -c --arg r "${role#gen-}" '.[$r] // empty')
[ "${role#gen-}" != "$role" ] && [ -n "$input" ] || note "skip:not-a-gen-role from=$from"

# A failed health check or recall leaves the agent with no standing law; say so to the agent, not only the log.
failwarn() {
  @jq@ -nc '{hookSpecificOutput: {hookEventName: "SubagentStart", additionalContext: "WARNING: the standing-law recall FAILED for this agent. Before your first measurement, run the recall yourself (tool search for \"hindsight\", then recall the den-law bank for your role)."}}'
  note "$1"
}
@curl@ -sS -m 5 -o /dev/null "$base/health" 2>/dev/null || failwarn "fail:health"

# Recall serializes server-side (~20-27s each, measured), so a parallel batch used to
# time out together: 4 at once gave 4/4 `fail:recall`. Queue on a lock instead, and cache
# the fixed per-role result so same-role teammates pay for one recall. Worst case
# 5 health + 150 lock wait + 80 recall = 235s, under the 240s hook timeout below; 150s
# of queue is ~6 distinct-role recalls. Only successful results are cached; TTL 10 min.
# ponytail: one global lock; per-role locks if recall ever parallelizes server-side.
cdir="$HOME/.claude/hindsight-recall-cache"
mkdir -p "$cdir"
cache="$cdir/$(printf '%s' "$input" | sha256sum | cut -c1-16)"
fresh() { [ -s "$cache" ] && [ -n "$(find "$cache" -mmin -10 2>/dev/null)" ]; }
if fresh; then
  resp=$(cat "$cache"); src=cache
else
  exec 9>"$HOME/.claude/hindsight-recall.lock"
  @flock@ -w 150 9 || failwarn "fail:recall"
  if fresh; then
    resp=$(cat "$cache"); src=cache
  else
    resp=$(@curl@ "${auth[@]}" -sS -f -m 80 -X POST "$base/v1/default/banks/$bank/memories/recall" \
      -H 'Content-Type: application/json' -d "$input" 2>/dev/null) || failwarn "fail:recall"
    [ "$(printf '%s' "$resp" | @jq@ '.results | length' 2>/dev/null)" -gt 0 ] 2>/dev/null \
      && printf '%s' "$resp" > "$cache.$$" && mv "$cache.$$" "$cache"
    src=ok
  fi
fi

# `types` already excludes observations; `obs` counts any that got through anyway.
obs=$(printf '%s' "$resp" | @jq@ '[.results[]? | select(.type == "observation")] | length' 2>/dev/null)
# Whole results, in rank order, while they fit 9000 chars: claude-code swaps a
# larger hook context for a preview and a file path, which the agent may never
# open. The four role queries returned 14.6-15.7k chars unbounded.
out=$(printf '%s' "$resp" | @jq@ -r --arg bank "$bank" --arg role "$role" '
  reduce (.results[]? | "- " + (.text // "")) as $l ([];
    if (map(length + 1) | add // 0) + ($l | length) < 9000 then . + [$l] else . end) as $law
  | if ($law | length) == 0 then empty
    else (["## Standing law for \($role) (recalled from \($bank), world and experience facts only)", ""] + $law) | join("\n")
    end' 2>/dev/null)
[ -n "$out" ] || note "fail:empty from=$from"

@jq@ -nc --arg c "$out" '{hookSpecificOutput: {hookEventName: "SubagentStart", additionalContext: $c}}'
note "$src from=$from results=$(printf '%s' "$resp" | @jq@ '.results | length') observations=$obs chars=${#out}"
