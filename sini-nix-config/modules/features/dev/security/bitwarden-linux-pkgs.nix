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
      age.secrets = lib.mkIf hasMasterPassword {
        bitwarden-master-password = {
          rekeyFile = masterPasswordFile;
          mode = "600";
        };
      };

      home.packages = [
        pkgs.libsecret

        # Store the master password in the login keyring, but only once it is
        # proven to open the vault. Writing it unverified is worse than not
        # writing it: the pinentry below would then hand rbw the same wrong
        # password on all three of its attempts, and every later unlock would
        # fail with nothing on screen pointing at the keyring.
        (pkgs.writeShellApplication {
          name = "rbw-remember";
          runtimeInputs = [
            pkgs.libsecret
            config.programs.rbw.package
          ];
          text = ''
            export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

            # Held so a failed check can put back a working entry rather than
            # leaving the host worse off than before it ran.
            previous=$(secret-tool lookup service rbw 2>/dev/null || true)

            echo "Enter the Bitwarden master password (stored in the login keyring):"
            secret-tool store --label='rbw master password' service rbw

            # An already-unlocked vault makes `rbw unlock` return success
            # without ever calling pinentry, which would "verify" nothing.
            rbw lock >/dev/null 2>&1 || true

            if rbw unlock; then
              echo "verified: the vault unlocks from the keyring entry"
            else
              if [ -n "$previous" ]; then
                # printf, not echo: a piped secret keeps its trailing newline.
                printf '%s' "$previous" | secret-tool store --label='rbw master password' service rbw
                echo "verification failed - restored the previous keyring entry" >&2
              else
                secret-tool clear service rbw >/dev/null 2>&1 || true
                echo "verification failed - keyring entry removed, rbw will prompt as before" >&2
              fi
              exit 1
            fi
          '';
        })
      ];
    };
}
