#!/usr/bin/env bash
# Render this session's transcript and retain it as tier:episode.
#
# Fails OPEN at every step, like the recall path: a memory service that
# is down must never delay or break a session close.
#
# Usage: as a SessionEnd hook (payload on stdin), or by hand for the
# disk sweep:
#   hindsight-archive.sh <transcript.jsonl> [session_id] [project]
#
# The sweep passes `project` rather than letting it be derived, because
# a transcript on disk sits under Claude Code's MUNGED directory name
# (`-home-sini-Documents-repos-sini-den-ag-design`) and un-munging it is
# not decidable: `-` is both the path separator and a character inside
# `den-ag-design`. The hook path has no such problem — `cwd` arrives in
# the payload as a real path.
set -uo pipefail
base="@endpoint@"
bank="@bank@"
# den-law gates reads and writes (kubernetes/services/ai/hindsight.nix):
# every bank call carries the user's token.
auth=(-H "Authorization: Bearer $(cat @tokenFile@ 2>/dev/null)")
strategy="@strategy@"

# ★ FAIL OPEN, BUT LEAVE A TRACE. Exiting 0 on every error is required —
# a memory service that is down must not delay a session close — and it
# is also what makes "never fired" and "fired and banked nothing" look
# identical from outside. They are different defects with different
# fixes, so each bail names its stage. This is the only reason the ARG_MAX
# bug below would have been findable had it shipped.
log="$HOME/.claude/hindsight-archive.log"
fail() { printf '%s\t%s\t%s\n' "$(date -Is)" "${session:-?}" "$1" >> "$log"; exit 0; }

# ★★★ UNCONDITIONAL FIRING LINE, BEFORE ANY BAIL. Without it "the hook NEVER
# FIRED" and "the hook FIRED AND DID NOTHING" are indistinguishable, and this
# script had THREE silent exits — unreadable transcript, empty session id, and a
# render under 400 bytes — none of which touched the log. Measured 2026-09-02:
# the owner exited and resumed, and afterwards the bail log held only a stale
# entry, the session's document was unchanged, and no operation had been queued.
# That is consistent with the hook never running AND with it running against a
# payload lacking transcript_path or session_id, which are different defects.
# SessionEnd's payload fields are UNMEASURED — claude.nix documents SessionStart,
# SubagentStart and SubagentStop, deliberately not this one — so the guess is not
# idle. This line is what turns the next session close into evidence.
printf '%s\tFIRED\targv=%s\n' "$(date -Is)" "$#" >> "$log"

if [ $# -ge 1 ]; then
  transcript="$1"
  session="${2:-$(basename "$transcript" .jsonl)}"
  cwd="$(dirname "$transcript")"
else
  payload=$(cat 2>/dev/null || true)
  transcript=$(printf '%s' "$payload" | @jq@ -r '.transcript_path // empty' 2>/dev/null || true)
  session=$(printf '%s' "$payload" | @jq@ -r '.session_id // empty' 2>/dev/null || true)
  cwd=$(printf '%s' "$payload" | @jq@ -r '.cwd // empty' 2>/dev/null || true)
fi
# These two exits were SILENT and are the most likely place a real SessionEnd
# firing disappears — a payload without transcript_path or session_id looks
# exactly like a hook that never ran.
[ -r "${transcript:-}" ] || fail "no-transcript:${transcript:-EMPTY}"
[ -n "${session:-}" ] || fail "no-session-id"

# `project:` records where the work HAPPENED, never what it was about.
# It localises the wrong-working-directory class: a measurement taken in
# the wrong tree reads as authoritative unless something says where it
# was taken.
project="${3:-$(basename "${cwd:-unknown}")}"
case "$project" in ""|.|/|-*) project="unknown" ;; esac

@curl@ -sS -m 2 -o /dev/null "$base/health" 2>/dev/null || fail "health"

# ★★ EVERYTHING GOES THROUGH FILES, NEVER THROUGH ARGV OR A SHELL VAR.
# A rendered session is ~386 KB and one line of a 5.8 MB transcript can
# be 16 KB; `--arg c "$turns"` and `curl -d "$body"` BOTH exceed ARG_MAX
# and die with "argument list too long". Measured 2026-09-01 against the
# real transcript before this path ever ran live. It is the worst shape
# of failure available here: the script still exits 0, the hook reports
# success, and NOTHING is ever banked — on every session, because every
# real session clears the limit. `--rawfile` and `-d @file` are why the
# size stops mattering.
turns=$(mktemp) || exit 0
req=$(mktemp) || { rm -f "$turns"; exit 0; }
trap 'rm -f "$turns" "$req"' EXIT

@jq@ -c -f "@renderer@" "$transcript" > "$turns" 2>/dev/null || fail "render"
# A session that rendered to almost nothing has nothing to extract, and
# a retain against it still costs a full LLM pass per chunk.
[ "$(wc -c < "$turns")" -lt 400 ] && exit 0

# document_id is the SESSION id and update_mode is replace, so this is
# idempotent: the SessionEnd hook and the disk sweep are the same write,
# and running either twice replaces rather than duplicates.
# The HOOK wants fire-and-forget: a session close must not wait on 30
# chunks of extraction. The BACKFILL wants the opposite — one session
# at a time, so progress is observable, an interrupt loses at most one
# session, and 90 of them do not land on the queue at once. Same write
# path, one switch.
async=true
[ "${HINDSIGHT_ARCHIVE_SYNC:-0}" = "1" ] && async=false

@jq@ -nc --rawfile c "$turns" --argjson async "$async" \
  --arg s "$session" --arg p "$project" --arg st "$strategy" \
  '{async: $async, items: [{
      content: $c,
      context: "One agent working session, rendered transcript.",
      document_id: $s,
      update_mode: "replace",
      strategy: $st,
      tags: ["tier:episode", ("project:" + $p), ("session:" + $s)]
    }]}' > "$req" 2>/dev/null || fail "build"

# The timeout follows the mode. Async returns as soon as the retain is
# ACCEPTED, so 30s is generous. Sync returns when EXTRACTION FINISHES,
# and one real 5.8 MB session measured ~10 minutes across ~30 chunks —
# 30s there would abort every session and log a "post" bail that looks
# like the service is down.
timeout=30
[ "$async" = "false" ] && timeout=3600

@curl@ "${auth[@]}" -sS -m "$timeout" -X POST "$base/v1/default/banks/$bank/memories" \
  -H 'Content-Type: application/json' --data-binary @"$req" \
  >/dev/null 2>&1 || fail "post"
exit 0
