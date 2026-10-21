#!/usr/bin/env bash
# PreToolUse/Bash: refuse the shapes the prose law forbids. Exit 2 blocks with stderr as feedback.
set -uo pipefail
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0
# Command position: line start, after ; & | ( ` or $(, past env assignments and timeout/sudo.
at='(^|[;&|(`]|\$\()[[:space:]]*(([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*|sudo|env|timeout[[:space:]]+[^[:space:]]+)[[:space:]]+)*'
refuse() { printf '%s\n' "$1" >&2; exit 2; }

if printf '%s\n' "$cmd" | grep -Eq "${at}pkill[[:space:]]([^;&|]*[[:space:]])?(-[a-zA-Z]*f|--full)"; then
  refuse "Refused: pkill -f matches its own shell and has killed the orchestrator. Kill only a PID you captured with \$! at launch."
fi
if printf '%s' "$cmd" | tr '\n' ' ' | grep -Eq '(while|until)[[:space:]].*pgrep[[:space:]]([^;&|]*[[:space:]])?(-[a-zA-Z]*f|--full)'; then
  refuse "Refused: a pgrep -f wait loop matches its own command line and never ends. Wait on a \$! PID (while kill -0 \$pid) or a marker the producer writes, under timeout."
fi
if ! printf '%s' "$cmd" | grep -q 'MemoryMax=' \
  && printf '%s\n' "$cmd" | grep -Eq "${at}nix[[:space:]]+(eval|build|flake[[:space:]]+check|develop[[:space:]].*(-c|--command)[[:space:]]+ci)([[:space:]]|\$)"; then
  refuse "Refused: run nix eval/build/flake check uncapped. Re-run as:
systemd-run --user --scope -q -p MemoryMax=12G $cmd
(rc 137 under the cap is a finding; never re-run it uncapped.)"
fi
# The Bash tool runs zsh: these bash idioms fail, several silently.
lint=""
printf '%s' "$cmd" | grep -Eq '\$\{!' && lint="$lint
  \${!var} -> \${(P)var}"
printf '%s' "$cmd" | grep -Eq '\$\{?PIPESTATUS' && lint="$lint
  \$PIPESTATUS -> \$pipestatus"
printf '%s\n' "$cmd" | grep -Eq "${at}shopt([[:space:]]|\$)" && lint="$lint
  shopt -> setopt"
printf '%s' "$cmd" | grep -Eq '"\$[A-Za-z_][A-Za-z0-9_]*:[lhtres]' && lint="$lint
  \"\$var:x\" applies a zsh history modifier -> brace it: \"\${var}:x\""
printf '%s\n' "$cmd" | grep -Eq '(^|[;&|[:space:]])path=|for[[:space:]]+path[[:space:]]' && lint="$lint
  path= rebinds PATH in zsh -> rename the variable"
[ -z "$lint" ] || refuse "Refused: the Bash tool runs zsh; fix these bash idioms:$lint"
exit 0
          '';
