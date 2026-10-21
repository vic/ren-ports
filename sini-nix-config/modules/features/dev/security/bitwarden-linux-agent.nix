{ ren, lib, ... }:
{
  ren.aspects.dev-security-bitwarden.homeLinux =
    {
      config,
      host,
      is,
      pkgs,
      user,
      ...
    }:
    let
      isGraphical = is ren.aspects.workstation host;
      v = import ./_bitwarden-vars.nix { inherit config lib user isGraphical; };
      inherit (v) hasMasterPassword masterPasswordFile masterPasswordPath unlockTarget;
    in
    {
      # Start the agent at graphical login, still LOCKED — unlocking stays
      # lazy. rbw's ssh-agent calls unlock_state() from both request_identities
      # and sign, and unlock_state runs pinentry when the vault needs it, so
      # the master password is asked for only when something actually reaches
      # into the vault. Nothing is cached anywhere.
      #
      # A unit is needed because rbw-agent is otherwise spawned on demand by
      # the rbw CLI, and SshAgent::run binds the ssh-agent socket when the
      # *agent starts*, not when the vault unlocks. With no agent there is no
      # socket, so ssh-agent-mux has no rbw upstream to attach to until some
      # unrelated rbw command happens to run.
      #
      # graphical-session.target rather than default.target: an unlock
      # triggered through the ssh agent has no rbw client to supply an
      # environment, so pinentry inherits the agent's own, and pinentry-gnome3
      # needs the session's display and bus to draw a prompt. On a headless
      # host the target never activates and this is inert.
      # Two units, because the agent and the unlock have different scopes.
      #
      # The agent is not graphical: on any host its ssh-agent socket is what
      # ssh-agent-mux attaches to, so it belongs on default.target. It is
      # needed at all because rbw-agent is otherwise spawned on demand by the
      # rbw CLI, and SshAgent::run binds that socket when the *agent starts*,
      # not when the vault unlocks — no agent, no socket to attach to.
      systemd.user.services.rbw-agent =
        let
          # An agent the rbw CLI spawned on demand holds an exclusive flock on
          # the pidfile and outlives the session that created it, because it
          # double-forks out of any cgroup. --no-daemonize has no graceful
          # "already running" path — that exit-23 branch exists only in the
          # daemonizing arm — so it just fails to take the lock and exits 1,
          # which Restart turns into a loop. Evict the squatter first, then
          # wait for the lock to actually clear: quit only asks it to leave.
          claimAgent = pkgs.writeShellScript "rbw-agent-claim" ''
            ${config.programs.rbw.package}/bin/rbw stop-agent 2>/dev/null || true
            pidfile="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/rbw/pidfile"
            for _ in $(${pkgs.coreutils}/bin/seq 50); do
              ${pkgs.util-linux}/bin/flock -n "$pidfile" true 2>/dev/null && exit 0
              ${pkgs.coreutils}/bin/sleep 0.1
            done
          '';
        in
        {
          Unit = {
            Description = "rbw agent (Bitwarden vault and ssh-agent backend)";
            After = [ "default.target" ];
            # Every activation evicts and restarts the agent, which drops the
            # decrypted vault with it. Without this the unlock unit stays
            # active (exited) from an earlier run and never fires again, so a
            # switch silently leaves the vault locked and nothing prompts.
            Wants = [ "rbw-unlock.service" ];
            # Without a limit that bites, a permanently unavailable lock just
            # restarts every 5s forever and the unit never reports failed.
            StartLimitIntervalSec = 120;
            StartLimitBurst = 5;
          };
          Service = {
            # --no-daemonize keeps it in the foreground so Type=simple can
            # track the real process rather than a daemonized orphan.
            Type = "simple";
            ExecStartPre = "-${claimAgent}";
            ExecStart = "${config.programs.rbw.package}/bin/rbw-agent --no-daemonize";
            Restart = "on-failure";
            RestartSec = 5;
          };
          Install.WantedBy = [ "default.target" ];
        };
    };
}
