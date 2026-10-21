# hindsight options, part 2 (archiveHook, handoffRepos, episodeStrategy).
{ lib }:
{
  archiveHook = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Install a SessionEnd hook that renders the session transcript and
      retains it as `tier:episode`.

      On since 2026-09-01. It was opt-in until the bank's `episode` strategy
      was settled, because a mission that extracts the wrong thing writes
      sediment into the same bank recall serves law from. What discharged
      that, in order:

        · the strategy NAME resolves. Armed pair, same content, same call:
          `episode` returned extracted prose, a deliberately bogus name
          returned THE RAW JSONL as one verbatim fact at HTTP 200. Upstream
          falls back on an unknown name with only a server-side log line, so
          a typo here banks unextracted transcripts and reports success.
        · one real 5.8 MB session, end to end: 28 facts, 0 unlabelled,
          19 measurement / 5 correction / 4 instrument, every fact carrying
          tier: project: session: and kind:.
        · attribution holds. The corrections name "Peer message" and "the
          scout" rather than the owner — which is the renderer's peer
          re-labelling working, and is the whole reason it exists.

      SessionEnd, not Stop. Upstream's plugin hooks Stop and carries a
      retain cursor to go with it, because Stop fires every time the agent
      finishes responding — without a cursor that re-extracts the whole
      transcript on every turn, at LLM cost, against a growing session.
      Archival wants one firing per session, so it hooks the event that
      gives exactly that.

      The cost of SessionEnd is a session that dies without firing it, which
      is never captured. That is covered by construction rather than by
      hoping: `document_id` is the session id, so the disk sweep over
      `~/.claude/projects/**` and this hook are the same write, and either
      one may run twice or in either order.
    '';
  };

  handoffRepos = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ "Documents/repos/sini/den-ag-design" ];
    description = ''
      Repositories, relative to the home directory, whose `STATUS/HANDOFF.md`
      git history is reconciled into the bank by
      `hindsight-handoff-reconcile`. A host without the checkout skips it —
      the unit's start condition is the file's presence.
    '';
  };

  episodeStrategy = lib.mkOption {
    type = lib.types.str;
    default = "episode";
    description = ''
      Name of the bank's retain strategy for session transcripts.

      Named once, here, because an unknown strategy name FAILS SILENTLY:
      upstream's `apply_strategy` logs a warning and returns the resolved
      config unchanged (`config_resolver.py`, "Unknown retain strategy
      '<name>', using resolved config as-is"). A typo therefore does not
      error — it retains the transcript under the bank's DEFAULT mission,
      which is the law mission, whose closing instruction is to ignore
      session narration. The result is a retain that reports success and
      banks almost nothing.
    '';
  };
}
