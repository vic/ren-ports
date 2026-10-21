{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
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
      # On a graphical host the unlock is graphical: pinentry-gnome3 needs the
      # session's display and bus, and those only reach the user manager once
      # the graphical session imports them — after default.target, which is why
      # it cannot ride along with the agent there.
      #
      # A headless host has no such target, so the unit used to be permanently
      # inert and the vault permanently locked: rbw's ssh-agent socket exists
      # and serves nothing, and the mux silently offers the standard agent's
      # keys only. That is not a degraded mode, it is a broken one — a handoff
      # host cannot authenticate to any remote whose key lives in the vault.
      # So the install target follows the host: graphical-session.target where
      # there is a session to wait for, default.target where the unlock is
      # unattended off the agenix master password above.
      #
      # Kept separate from the agent rather than folded in as ExecStartPost so
      # that a dismissed or mistyped prompt fails only this unit. The vault
      # then stays locked and rbw's own lazy path prompts on next use; the
      # agent is never at risk.
      systemd.user.services.rbw-unlock =
        let
          # After= orders against the agent's *start*, which under Type=simple
          # is the fork, not the socket bind. rbw's ensure_agent() reacts to a
          # missing socket by spawning an agent that immediately exits 23 on
          # the pidfile lock, then rechecks and gives up — so without this wait
          # the unlock just quietly does nothing.
          unlockAtLogin = pkgs.writeShellScript "rbw-unlock-at-login" ''
            # The agent lives on default.target and so can restart before the
            # session has a display. With a password source that does not
            # matter — the keyring lookup only needs the bus, and the agenix
            # file needs nothing at all; with neither there is nothing to
            # prompt on, and leaving the vault locked beats a failed unit.
            ${lib.optionalString hasMasterPassword ''
              # agenix decrypts into tmpfs during home-manager activation, which
              # is a system service and so is not ordered against this user
              # manager. Wait for the file rather than assume it (same poll the
              # ssh signing-key loader uses) — a miss here would fall through to
              # a pinentry that cannot prompt and fail the unit on a cold boot.
              for _ in $(${pkgs.coreutils}/bin/seq 100); do
                [ -r ${lib.escapeShellArg masterPasswordPath} ] && break
                ${pkgs.coreutils}/bin/sleep 0.1
              done
            ''}
            if [ -z "''${WAYLAND_DISPLAY:-}''${DISPLAY:-}" ] \
              && [ ! -r "${if hasMasterPassword then masterPasswordPath else "/nonexistent"}" ] \
              && ! ${pkgs.libsecret}/bin/secret-tool lookup service rbw >/dev/null 2>&1; then
              exit 0
            fi
            sock="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/rbw/socket"
            for _ in $(${pkgs.coreutils}/bin/seq 100); do
              [ -S "$sock" ] && break
              ${pkgs.coreutils}/bin/sleep 0.1
            done
            exec ${config.programs.rbw.package}/bin/rbw unlock
          '';
        in
        {
          Unit = {
            Description = "Unlock the rbw vault at login";
            After = [
              unlockTarget
              "rbw-agent.service"
            ];
            Wants = [ "rbw-agent.service" ];
            # PartOf the agent as well as the target: RemainAfterExit keeps
            # this unit active for the life of one agent, and it has to be
            # stopped when that agent goes away before it can run for the next.
            PartOf = [
              unlockTarget
              "rbw-agent.service"
            ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = unlockAtLogin;
            # pinentry blocks until answered, and the default 90s start
            # timeout would kill the prompt out from under you.
            TimeoutStartSec = "infinity";
          };
          Install.WantedBy = [ unlockTarget ];
        };
    };
}
