# beads: tracker drift check (see beads.nix header). Returns the writeShellApplication.
pkgs: beadsDir:
pkgs.writeShellApplication {
  name = "beads-tracker-drift";
  runtimeInputs = [
    pkgs.git
    pkgs.jq
    pkgs.coreutils
  ];
  text = ''
    # den-ag-design sessions only; see claude.nix gated.sh.
    # shellcheck source=/dev/null
    . "$HOME/.claude/gated.sh" 2>/dev/null || exit 0
    gated || exit 0

    r=$(dirname "''${BEADS_DIR:-${beadsDir}}")

    if ! git -C "$r" rev-parse --git-dir > /dev/null 2>&1; then
      echo "TRACKER: $r is not a git checkout — drift NOT checked."
      exit 0
    fi

    u=$(git -C "$r" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
    if [ -z "$u" ]; then
      echo "TRACKER: no upstream for $(git -C "$r" branch --show-current) — drift NOT checked."
      exit 0
    fi

    # The only network call, and it is bounded: a session must never block on
    # it. ★ A FAILED FETCH IS SAID SO, never folded into "in sync" — without
    # the fetch the counts run against a stale remote ref, and a clone 205
    # commits behind reads CLEAN. That is the exact miss this hook exists for,
    # so the failure mode must not reproduce it.
    stale=""
    if ! timeout 15 git -C "$r" fetch --quiet 2>/dev/null; then
      stale=" [fetch FAILED — counted against a STALE remote ref]"
    fi

    behind=$(git -C "$r" rev-list --count "HEAD..$u" 2>/dev/null || true)
    ahead=$(git -C "$r" rev-list --count "$u..HEAD" 2>/dev/null || true)

    # Checked one at a time: concatenating first would let an EMPTY behind
    # beside a "0" ahead read as the single digit 0 and pass as clean.
    for v in "$behind" "$ahead"; do
      case "$v" in
        "" | *[!0-9]*)
          echo "TRACKER: rev-list failed — drift NOT checked.$stale"
          exit 0
          ;;
      esac
    done

    if [ "$behind" -gt 0 ]; then
      echo "TRACKER IS $behind COMMIT(S) BEHIND $u.$stale"
      echo "  git -C $r pull --ff-only   — br then auto-imports the JSONL on its next command."
      if [ "$ahead" -gt 0 ]; then
        echo "  DIVERGED: also $ahead unpushed. Do not --ff-only over local work; reconcile first."
      fi
    elif [ "$ahead" -gt 0 ]; then
      echo "TRACKER: $ahead unpushed commit(s) on $(git -C "$r" branch --show-current).$stale"
    else
      # Printed even when clean, on purpose: this line's ABSENCE then means the
      # hook did not run, rather than meaning there was nothing to say.
      echo "TRACKER: in sync with $u.$stale"
    fi
  '';
}
