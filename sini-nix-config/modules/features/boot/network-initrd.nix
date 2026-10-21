# Network initrd unlock: initrd networking, Clevis+Tang LUKS/ZFS unlock, initrd SSH.
# Wireless support lives in boot-wireless-initrd; keys/secrets in network-initrd-keys.nix.
{ ren, ... }:
{
  ren.aspects.boot-network-initrd.nixos =
    {
      config,
      is,
      host,
      lib,
      resolved-users,
      ...
    }:
    let
      # SSH keys for users in the "wheel" or "admins" groups (resolved-users channel pool).
      wheelSshKeys = lib.concatMap (
        u:
        lib.optionals (builtins.any (g: g == "admins" || g == "wheel") (u.groups or [ ])) (u.sshKeys or [ ])
      ) resolved-users;

      jweToken = builtins.path {
        path = host.secretPath + "/zroot-key.jwe";
        name = "zroot-key.jwe";
      };

      # Collect network driver modules from facter hardware report
      baseNetworkDriverModules = lib.unique (
        lib.flatten (
          lib.filter (x: x != null) (
            map (iface: iface.driver_modules or null) config.facter.report.hardware.network_interface
          )
        )
      );

      moduleDependencies = {
        "mlx4_core" = [ "mlx4_en" ];
        "iwlwifi" = [ "iwlmvm" ];
      };

      additionalDriverModules = lib.unique (
        lib.flatten (map (mod: moduleDependencies.${mod} or [ ]) baseNetworkDriverModules)
      );

      networkDriverModules = lib.unique (baseNetworkDriverModules ++ additionalDriverModules);
    in
    {
      boot.initrd = {
        availableKernelModules = [
          "bridge"
          "bonding"
          "8021q"
          "tpm_crb"
          "tpm_tis"
        ]
        ++ networkDriverModules;

        clevis = lib.mkIf (is ren.aspects.disk-zfs-disk-single host) {
          enable = true;
          useTang = true;
          devices.zroot.secretFile = jweToken;
        };

        systemd = {
          inherit (config.systemd) network;

          # Wait for clevis to do its thing before loading ZFS keys.
          services.zfs-import-zroot.preStart = ''
            /bin/sleep 10
            ${lib.getExe config.boot.zfs.package} load-key -a
          '';
        };

        network = {
          enable = true;
          ssh = {
            enable = true;
            port = 22;
            authorizedKeys = wheelSshKeys;
            hostKeys = [
              config.age.secrets.initrd_host_ed25519_key.path
            ];
          };
        };
      };
    };
}
