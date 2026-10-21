{ ren, lib, inputs, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
  settingsT = t.submodule {
    options = {
      wipeRootOnBoot = opt t.bool true; # Roll the root filesystem back to a pristine state on boot
      wipeHomeOnBoot = opt t.bool false; # Roll the home filesystem back to a pristine state on boot
    };
  };
in
{
  ren.kinds.machine.impermanence = opt settingsT { };

  ren.aspects.impermanence = {
    includes = with ren.aspects; [
      impermanence-persist-collector
      impermanence-persist-home-collector
      impermanence-btrfs
      impermanence-zfs
    ];

    # The static paths go through the channels like every aspect's, so the
    # persist/cache channels carry the whole set.
    persist.files = [
      "/etc/machine-id"
      "/etc/zfs/zpool.cache"
      "/etc/adjtime"
      "/root/.bash_history"
      # Host key for systemd LoadCredentialEncrypted. Must persist so
      # blobs encrypted against it (e.g. libvirt's secrets-encryption-key
      # under the persisted /var/lib/libvirt) stay decryptable across boots.
      "/var/lib/systemd/credential.secret"
    ];
    cache.directories = [
      "/var/lib/nixos"
      "/var/tmp"
      "/srv"
    ];

    nixos = {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      options.impermanence.ignorePaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Paths ignored by persistence diff tooling.";
      };

      config = {
        impermanence.ignorePaths = [
          "/etc/NIXOS"
          "/etc/.clean"
          "/etc/.updated"
          "/etc/.pwd.lock"
          "/var/.updated"
          "/etc/subgid"
          "/etc/subuid"
          "/etc/shadow"
          "/etc/group"
          "/etc/passwd"
          "/root/.nix-channels"
          "/var/lib/systemd/linger/"
          "/var/lib/systemd/random-seed"
          "/etc/fwupd/fwupd.conf"
          "/var/lib/tpm2-udev-trigger/hash.txt"
          "/etc/ssh/authorized_keys.d/"
        ];

        # Fix /var/lib and /var/lib/private permissions after impermanence creates them
        system.activationScripts."var-lib-private-perms" = {
          deps = [
            "persist-files"
            "createPersistentStorageDirs"
          ];
          text = ''
            mkdir -p /var/lib/private
            chown root:root /var/lib
            chmod 0755 /var/lib
            chown root:root /var/lib/private
            chmod 0700 /var/lib/private
          '';
        };

        environment.persistence = {
          "/cache" = {
            enable = true;
            persistentStoragePath = "/cache";
            hideMounts = true;
          };

          "/persist" = {
            enable = true;
            hideMounts = true;
          };
        };
      };
    };
  };
}
