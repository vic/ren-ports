# ccstatusline line 1: where you are and what is unlanded (sep = shared separator widget).
sep:
  # Line 1 — WHERE YOU ARE and WHAT IS UNLANDED. Every widget here is one
  # the close protocol asks about: which worktree holds the writer, what
  # is uncommitted, what is committed but unpushed.
  [
    {
      type = "current-working-dir";
      color = "cyan";
      # Drops the "cwd: " label; a path does not need naming.
      rawValue = true;
      # metadata is record(string,string) in the schema — booleans are
      # compared against the STRING "true", so `true` would read as unset.
      metadata.abbreviateHome = "true";
    }
    sep
    {
      type = "git-branch";
      color = "magenta";
      metadata.hide = "no-git";
    }
    {
      type = "git-changes";
      color = "yellow";
      metadata.hide = "no-git";
    }
    {
      # ↑n↓m against upstream: the "unpushed commits" half of the close
      # protocol, and the one a clean `git status` hides completely.
      # `hide` is deliberately NOT set here, unlike its neighbours:
      # in sync the widget returns null on its own, so the flag only ever
      # gates "(no git)" and "(no upstream)" — and a branch with no
      # upstream is the exact shape a fresh .worktrees/<task> takes, which
      # is where unpushed work strands.
      type = "git-ahead-behind";
      color = "brightRed";
    }
    {
      # Renders nothing outside a worktree, so it is a positive signal:
      # visible ⇒ you are in .worktrees/<task> and are its single writer.
      type = "worktree-name";
      color = "yellow";
    }
  ]
