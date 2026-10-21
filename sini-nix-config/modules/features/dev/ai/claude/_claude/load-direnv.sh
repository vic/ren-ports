#!/usr/bin/env bash
# Refresh the CLAUDE_ENV_FILE snapshot from direnv for the CURRENT directory.
#
# ★ THE HAZARD THIS SHAPE AVOIDS: evaluating direnv on every shell fork-bombs the host,
# and an agent asked to fix it re-triggers the same loop. So this runs on exactly TWO
# hook events — session start and directory change — and writes a SNAPSHOT the harness
# then reads per shell. It never evaluates during a Bash call.
set -uo pipefail
snap="${CLAUDE_ENV_FILE:-$HOME/.claude/direnv-snapshot.sh}"
mkdir -p "$(dirname "$snap")"
# No .envrc here: leave whatever the last directory established rather than blanking it,
# so moving into an unmanaged directory does not strip the tools mid-task.
[ -e .envrc ] || exit 0
command -v direnv >/dev/null || exit 0
tmp="$(mktemp)"
if direnv export bash 2>/dev/null > "$tmp"; then
  # Write via temp+mv: a half-written snapshot is sourced by every later shell, so a
  # partial write is worse than a stale one.
  mv "$tmp" "$snap"
else
  rm -f "$tmp"
fi
exit 0
          '';
