hook_payload=""
[ -t 0 ] || hook_payload=$(cat 2>/dev/null || true)
hook_field() { printf '%s' "$hook_payload" | jq -r "($1) // empty" 2>/dev/null || true; }
sid=$(hook_field .session_id)
marker=""
if [ -n "$sid" ] && [ -n "${XDG_RUNTIME_DIR:-}" ]; then
  marker="$XDG_RUNTIME_DIR/claude-gated/$sid"
fi

gated() {
  [ -n "$marker" ] || return 1
  if [ "$(hook_field .hook_event_name)" = SessionStart ]; then
    case "$(realpath -m "$(hook_field .cwd)" 2>/dev/null)" in
      @GATED_CASES@)
        # The model reaches SessionStart only; ctx_pct reads it back from here.
        mkdir -p "${marker%/*}" 2>/dev/null \
          && hook_field '.model | if type == "string" then . else .id end' > "$marker" 2>/dev/null \
          || true
        ;;
    esac
  fi
  [ -e "$marker" ]
}

# ★ DIVISOR DEFAULTS TO 1,000,000 (owner-ruled 2026-08-31): every orchestrator is
# Opus or Fable, and transcript_path is always the ORCHESTRATOR's window, never a
# subagent's. It fails toward UNDER-reporting, so an orchestrator on a 200K model
# would read 5x low and reach compaction rather than raise a false alarm.
# ★ NEVER TAKE THE MODEL FROM THE TRANSCRIPT. It records `claude-opus-5` with the
# `[1m]` marker STRIPPED (measured: 218/218 assistant messages) while the
# SessionStart payload records `claude-opus-5[1m]`. Trusting it selects a 200000
# divisor and reports 133% where the truth is 26.6% — tripping every gate at once.
# The window's last usage, or nothing. This runs on every tool call, so read the tail
# first: the last usage record is almost always there; the whole file is the fallback.
ctx_tokens() {
  local t tok
  local q='fromjson? | select(.type == "assistant" and .isSidechain != true)
           | .message.usage? // empty
           | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)'
  t=$(hook_field .transcript_path)
  if [ -z "$t" ] || [ ! -s "$t" ]; then return 0; fi
  tok=$(tail -n 400 "$t" | jq -Rr "$q" 2>/dev/null | tail -n 1 || true)
  [ -n "$tok" ] || tok=$(jq -Rr "$q" "$t" 2>/dev/null | tail -n 1 || true)
  case "$tok" in "" | *[!0-9]*) ;; *) echo "$tok" ;; esac
}

# Percent of the window for a token count (default: ctx_tokens), or "?".
ctx_pct() {
  local model tok="${1-$(ctx_tokens)}" limit=1000000
  model=$(hook_field '.model | if type == "string" then . else .id end')
  if [ -z "$model" ] && [ -n "$marker" ]; then model=$(cat "$marker" 2>/dev/null || true); fi
  case "$model" in
    "" | *"[1m]") ;;
    claude-haiku-* | claude-sonnet-5) limit=200000 ;;
  esac
  if [ -z "$tok" ]; then echo "?"; return 0; fi
  awk -v t="$tok" -v l="$limit" 'BEGIN{printf "%.1f", t*100/l}'
}
        '';
