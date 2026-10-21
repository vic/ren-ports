# beads: SessionStart boot text (printed through a heredoc by beads-hooks.nix).
''
  Beads tracker — the workspace is pinned by BEADS_DIR, so it resolves from any cwd.
  
  BOOT ORDER. Read both before touching the tracker; neither is optional:
    1. STATUS/RESUME-PROMPT-ARCH.md   (in the BEADS_DIR checkout)
    2. STATUS/HANDOFF.md — the session-state channel. It is WHOLESALE-REPLACED at
       each close, so anything not deliberately re-carried is gone, and its
       COMMISSION field outranks its recommendation field.
  
  ARC STATE LIVES IN THE GRAPH. Derive every figure by query. Never quote a count
  from a document — including this one.
  
  NEVER PUT JSON IN THE MODEL'S LOOP. A command whose consumer is a program gets
  --json; a command whose consumer is you gets text. THE REASON IS TOKEN ECONOMY,
  not compression: `br ready --limit 0` is 45,540 bytes as text and 1,439,726 as
  --json — 31x for identical information, because you find the structure yourself
  and the braces buy nothing. That holds with every compression layer switched
  off. Read bodies through the renderer (STATUS/br-cat.sh <id>... > file, then
  Read the file): structured in, rendered out. Filter corpora IN THE SCRIPT — a
  sweep that hands you the corpus to grep mentally is the one that reports clean
  without having measured anything.
  
  NOT AN ESCAPE HATCH: --format toon. It dedups repeated keys, and a bead
  payload is nearly all free-text values, so it measures LARGER than --json
  here. Native text is the small form by a factor of ~30. Check any claim
  about this with `br <cmd> --format toon --stats`.
  
  ALWAYS PASS --limit 0. The bare list/ready forms cap silently.
  COMMAND REFERENCE, on demand: `br robot-docs guide` (52 lines).
''
