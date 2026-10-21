# gated.sh + handoff-commission.sh: den-ag-design orchestrator gating.
{ ... }:
{
  ren.aspects.dev-ai-agents-claude.homeManager =
    { config, lib, ... }:
    let
      # Projects, relative to home, whose sessions get the orchestrator hooks (gated.sh).
      # Matched exactly against the STARTING cwd, so a worktree below one stays ungated.
      gatedProjects = [ "Documents/repos/sini/den-ag-design" ];
    in
    {
      # Sourced by every den-ag-design hook. A session is GATED when it STARTED at one of
      # `gatedProjects`, keyed by session_id (marker written at SessionStart). Sourcing this
      # CONSUMES STDIN: a sourcing hook reads the payload via hook_field.
      home.file.".claude/gated.sh".text =
        builtins.replaceStrings
          [ "@GATED_CASES@" ]
          [
            (lib.concatMapStringsSep "|" (
              p: ''"$(realpath -m "${config.home.homeDirectory}/${p}")"''
            ) gatedProjects)
          ]
          (builtins.readFile ./_claude/gated.sh);

      # Compaction summarizes the conversation; SessionStart(compact) stdout is re-added verbatim.
      home.file.".claude/handoff-commission.sh" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          # SessionStart(compact): re-inject HANDOFF.md's COMMISSION field so live agent ids survive compaction.
          set -uo pipefail
          . "$HOME/.claude/gated.sh" 2>/dev/null || exit 0
          gated || exit 0
          f="${config.home.homeDirectory}/${lib.head gatedProjects}/STATUS/HANDOFF.md"
          out=$(awk '/^──.*COMMISSION FIELD/ {on=1} on && /^──/ && !/COMMISSION FIELD/ {exit} on' "$f" 2>/dev/null)
          if [ -n "$out" ]; then
            printf 'Re-injected after compaction from %s:\n%s\n' "$f" "$out"
          else
            printf 'COMMISSION field NOT FOUND in %s: read STATUS/HANDOFF.md before acting.\n' "$f"
          fi
          exit 0
        '';
      };
    };
}
