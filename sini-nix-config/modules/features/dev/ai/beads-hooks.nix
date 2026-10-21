# beads: Claude Code SessionStart hooks (tracker drift check + boot text).
#
# THE TRACKER HAS NO AUTOMATIC HOST-TO-HOST SYNC. The real channel is
# .beads/issues.jsonl through git, and only the PULL leg had no instrument
# (measured 2026-08-27: cortex sat 205 commits behind unnoticed). _beads/drift.nix is it.
{ ... }:
{
  ren.aspects.dev-ai-tools-beads.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      beadsDir = "${config.home.homeDirectory}/Documents/repos/sini/den-ag-design/.beads";
      trackerDrift = import ./_beads/drift.nix pkgs beadsDir;
      bootText = pkgs.writeText "beads-boot.txt" (import ./_beads/boot.nix);
    in
    {
      # br's plugin ships skills with NO hooks directory at all, so nothing fires on session
      # start or compaction on its own. This is our hook, deliberately invariant — no counts,
      # no binary-specific flags. SessionStart only — NOT CwdChanged, which fires on every
      # directory change and would put a network fetch behind each one. `|| true` so a drift
      # check never blocks a session.
      programs.claude-code.settings.hooks.SessionStart = [
        {
          hooks = [
            {
              type = "command";
              command = "${lib.getExe trackerDrift} || true";
            }
          ];
        }
        {
          hooks = [
            {
              type = "command";
              command = pkgs.writeShellScript "beads-session-boot" ''
                . "$HOME/.claude/gated.sh" 2>/dev/null || exit 0
                gated || exit 0
                cat ${bootText}
              '';
            }
          ];
        }
      ];
    };
}
