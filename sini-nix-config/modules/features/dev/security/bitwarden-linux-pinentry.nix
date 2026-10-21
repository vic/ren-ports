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
      isDevGui = is ren.aspects.dev-gui host;
      v = import ./_bitwarden-vars.nix { inherit config lib user isGraphical; };
      inherit (v) hasMasterPassword masterPasswordFile masterPasswordPath unlockTarget;
    in
    {
      # rbw-agent's pinentry. Serves the master password from the login
      # keyring, which PAM unlocks at graphical login (desktop/gdm.nix and
      # desktop/xdg-portal.nix already wire pam_gnome_keyring), so the vault
      # unlocks with no prompt. It also makes unlocking work from contexts
      # with no display at all — an rbw-agent spawned by a systemd service
      # otherwise dies trying to open a graphical pinentry. Falls back to the
      # interactive pinentry when the keyring holds no entry, which is why the
      # lookup happens before a single byte of the Assuan protocol is read.
      #
      # One-time setup per host: run `rbw-remember` (below), which stores the
      # password only after confirming it actually opens the vault.
      #
      # Note the master password now lives in the login keyring, i.e. behind
      # the login password — the same trust model as the SSH keys gcr already
      # holds there, but it does mean vault-at-rest security is now login
      # password strength.
      #
      # The agenix file is the headless source, tried after the keyring and
      # before the interactive fallback. Keyring first so a graphical host
      # behaves exactly as it did; the file is the only one of the three that
      # can answer on a machine with neither a keyring daemon nor a terminal.
      # At rest it is encrypted to the yubikey master identity and decrypted
      # to tmpfs mode 600 — the same handling as this user's ssh signing key,
      # which is a stronger resting place than the login-password keyring.
      programs.rbw.settings.pinentry = pkgs.writeShellScriptBin "pinentry-rbw" ''
        # glib's bus fallback covers this, but only when XDG_RUNTIME_DIR is
        # set; pin the address so keyring lookups also work from odd contexts.
        export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(${pkgs.coreutils}/bin/id -u)/bus}"

        password=$(${pkgs.libsecret}/bin/secret-tool lookup service rbw 2>/dev/null || true)
        ${lib.optionalString hasMasterPassword ''
          # `read` returns non-zero on a final line with no newline, so the
          # exit status cannot gate this — the value does.
          if [ -z "$password" ] && [ -r ${lib.escapeShellArg masterPasswordPath} ]; then
            IFS= read -r password < ${lib.escapeShellArg masterPasswordPath} || true
          fi
        ''}

        if [ -n "$password" ]; then
          # Assuan wants %, CR and LF percent-escaped. Both sources are read a
          # line at a time, so % is the only one that can survive the round-trip.
          escaped=''${password//%/%25}
          printf 'OK pinentry-rbw ready\n'
          while IFS=' ' read -r command _; do
            case $command in
              GETPIN) printf 'D %s\nOK\n' "$escaped" ;;
              BYE) printf 'OK\n'; exit 0 ;;
              *) printf 'OK\n' ;;
            esac
          done
        else
          exec ${
            lib.getExe (
              if isDevGui then pkgs.pinentry-gnome3 else pkgs.pinentry-tty
            )
          } "$@"
        fi
      '';
    };
}
