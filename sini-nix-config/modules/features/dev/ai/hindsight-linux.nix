# hindsight reconcilers as user units — Linux only, where systemd runs them.
#
# HANDOFFS, on SessionEnd. The hook only STARTS the unit: a sync retain of one
# handoff takes minutes and the backlog was 135, so running it inside the hook
# would either blow its timeout or hold a session close. systemd also gives the
# dedup for free — a start while the unit is already running joins that run, so
# a fleet of agents ending together is one reconcile, not a flood. No timer: the
# reconciler derives its whole backlog on every run, so any later session end
# picks up whatever an earlier one missed, and a host with no sessions ending
# writes no handoffs.
#
# SESSIONS, on a daily timer. Here SessionEnd CANNOT cover the gap, because the
# gap is exactly the sessions that never fired it (a killed or crashed session),
# and no later session's hook runs the sweep — measured 2026-09-26: 19 sessions
# on cortex awaiting publication, with nothing scheduled to publish them.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.dev-ai-mcp-hindsight.homeLinux =
    { host, user, config, pkgs, ... }:
    let
      h = import ./_hindsight-mcp/lib.nix { inherit lib pkgs host user config; };
      repos = map (r: "${h.home}/${r}") h.cfg.handoffRepos;
      over = { inherit (h.cfg) endpoint bank; inherit (h) tokenFile; };
      reconcile = pkgs.local.hindsight-handoff-reconcile.override (over // { inherit repos; });
      backfill = pkgs.local.hindsight-backfill.override over;
    in
    lib.mkIf (h.cfg.archiveHook && h.writer) {
      systemd.user.services.hindsight-handoff-reconcile = {
        Unit = {
          Description = "Retain unbanked STATUS/HANDOFF.md revisions into hindsight";
          # `|` makes these OR: run if any configured repository is checked out.
          ConditionPathExists = map (r: "|${r}/STATUS/HANDOFF.md") repos;
        };
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe reconcile;
        };
      };

      systemd.user.services.hindsight-backfill = {
        Unit.Description = "Publish settled Claude Code sessions missing from hindsight";
        Service = {
          Type = "oneshot";
          # Two hours settles a session that is merely idle; --sleep keeps the
          # sweep serial and spaced, as the 2026-09-01 flood taught.
          ExecStart = "${lib.getExe backfill} --min-age 120 --sleep 5";
        };
      };

      systemd.user.timers.hindsight-backfill = {
        Unit.Description = "Daily hindsight session backfill";
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      programs.claude-code.settings.hooks.SessionEnd = [
        {
          hooks = [
            {
              type = "command";
              command = "${config.systemd.user.systemctlPath} --user start --no-block hindsight-handoff-reconcile.service || true";
              timeout = 10;
            }
          ];
        }
      ];
    };
}
