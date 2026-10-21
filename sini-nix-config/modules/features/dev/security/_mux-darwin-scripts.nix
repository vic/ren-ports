# darwin signing-key loader + mux wrapper scripts.
{ pkgs, config }:
{
  # Load the git signing key into the standard agent once its socket is up
  # and the agenix secret is decrypted, from a dedicated launchd agent
  # rather than the mux wrapper (which raced the standard socket at login).
  signingKeyLoader = pkgs.writeShellScript "standard-ssh-agent-load-key" ''
    set -uo pipefail
    DARWIN_TEMP=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)
    DARWIN_TEMP="''${DARWIN_TEMP%/}"
    SOCK="$DARWIN_TEMP/standard-ssh-agent.sock"
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

    DARWIN_TEMP=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)
    DARWIN_TEMP="''${DARWIN_TEMP%/}"

    MUX_SOCK="$DARWIN_TEMP/ssh-agent-mux.sock"
    STANDARD_SOCK="$DARWIN_TEMP/standard-ssh-agent.sock"
    RBW_SOCK="$DARWIN_TEMP/rbw-$(id -u)/ssh-agent-socket"
    DESKTOP_SOCK="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
    GPG_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket 2>/dev/null \
      || echo "$HOME/.gnupg/S.gpg-agent.ssh")"

    # (The signing key is loaded into the standard agent by the
    # standard-ssh-agent-load-key launchd agent, not here.)

    # Pass all potential sockets to the multiplexer unconditionally.
    # ssh-agent-mux gracefully ignores missing upstream sockets and will
    # automatically connect to them if they are created later (e.g. when rbw is unlocked).
    ARGS=( "-l" "$MUX_SOCK" "$STANDARD_SOCK" "$DESKTOP_SOCK" "$RBW_SOCK" "$GPG_SOCK" )

    exec ${pkgs.ssh-agent-mux}/bin/ssh-agent-mux "''${ARGS[@]}"
  '';
}
