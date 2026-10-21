{ ... }:
{
  ren.aspects.dev-security-ssh-agent-mux = {
    homeLinux =
      { pkgs, config, ... }:
      let
        # Load the git signing key into the standard agent once its socket is up
        # and the agenix secret is decrypted. Runs as standard-ssh-agent's
        # ExecStartPost, so it reloads whenever that agent (re)starts and does not
        # race the mux the way loading it from the mux wrapper did (After= only
        # guarantees the unit started, not that ssh-agent bound its socket).
        signingKeyLoader = pkgs.writeShellScript "standard-ssh-agent-load-key" ''
          set -uo pipefail
          RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
          SOCK="$RUNTIME/standard-ssh-agent.sock"
          KEY="${config.age.secrets.user-signing-key.path or ""}"
          # A user without a signing key has nothing to load and nothing to wait for.
          [ -n "$KEY" ] || exit 0
          for _ in $(seq 1 100); do
            { [ -S "$SOCK" ] && [ -f "$KEY" ]; } && break
            sleep 0.1
          done
          [ -S "$SOCK" ] && [ -f "$KEY" ] \
            && SSH_AUTH_SOCK="$SOCK" ${pkgs.openssh}/bin/ssh-add "$KEY" 2>/dev/null
          exit 0
        '';
        wrapper = pkgs.writeShellScript "ssh-agent-mux-start" ''
          set -euo pipefail

          # Ensure XDG_RUNTIME_DIR is set
          if [ -z "''${XDG_RUNTIME_DIR:-}" ]; then
            export XDG_RUNTIME_DIR="/run/user/$(id -u)"
          fi

          MUX_SOCK="$XDG_RUNTIME_DIR/ssh-agent-mux.sock"
          STANDARD_SOCK="$XDG_RUNTIME_DIR/standard-ssh-agent.sock"
          RBW_SOCK="$XDG_RUNTIME_DIR/rbw/ssh-agent-socket"
          DESKTOP_SOCK="$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"
          # Asked of gpgconf rather than hardcoded: the path is derived from a
          # hash of the gnupg homedir, so it moves if programs.gpg.homedir does.
          # Resolvable whether or not the agent has started.
          GPG_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket 2>/dev/null \
            || echo "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh")"

          # (The signing key is loaded into the standard agent by that agent's
          # own ExecStartPost, not here.)

          # Pass all potential sockets to the multiplexer unconditionally.
          # ssh-agent-mux gracefully ignores missing upstream sockets and will
          # automatically connect to them if they are created later (e.g. when rbw is unlocked).
          ARGS=( "-l" "$MUX_SOCK" "$STANDARD_SOCK" "$DESKTOP_SOCK" "$RBW_SOCK" "$GPG_SOCK" )

          exec ${pkgs.ssh-agent-mux}/bin/ssh-agent-mux "''${ARGS[@]}"
        '';
      in
      {
        home.sessionVariables = {
          SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent-mux.sock";
        };

        systemd.user.services.standard-ssh-agent = {
          Unit = {
            Description = "Standard SSH Agent Backend";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/standard-ssh-agent.sock";
            ExecStartPost = "${signingKeyLoader}";
            Restart = "always";
          };
        };

        systemd.user.services.ssh-agent-mux = {
          Unit = {
            Description = "SSH Agent Multiplexer";
            After = [ "standard-ssh-agent.service" ];
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            ExecStart = "${wrapper}";
            Restart = "always";
          };
        };
      };
  };
}
