# LUKS2-encrypted btrfs disk layout with impermanence subvolumes (layout in btrfs-disko-layout.nix).
# Uses facter to auto-detect the disk when device_id is not set.
{ ren, lib, inputs, ... }:
{
  ren.kinds.machine.disk-btrfs-disko = ren.lib.opt (lib.types.submodule {
    options.device_id = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Disk device id (e.g., "ata-..." or "/dev/disk/by-id/...").
        If not set, auto-detects a single non-USB disk via facter.
      '';
    };
    options.swap_size = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Size of swap in MiB, 0 disables swap.";
    };
  }) { };

  ren.aspects.disk-btrfs-disko = {
    includes = with ren.aspects; [ disk-btrfs ];

    nixos =
      { config, host, ... }:
      let
        cfg = host.disk-btrfs-disko;
        native-disks = builtins.filter (f: f.driver != "usb-storage") config.facter.report.hardware.disk;
        disk-labels = map (
          disk:
          builtins.head (
            builtins.filter (f: builtins.substring 0 16 f == "/dev/disk/by-id/") disk.unix_device_names
          )
        ) native-disks;
        disk-device =
          if cfg.device_id != "" then
            if lib.hasPrefix "/dev/" cfg.device_id then cfg.device_id else "/dev/disk/by-id/" + cfg.device_id
          else if builtins.length disk-labels == 1 then
            builtins.head disk-labels
          else
            abort ("Multiple disks found. Please set disk-btrfs-disko.device_id. Found: " + toString disk-labels);
      in
      {
        imports = [ inputs.disko.nixosModules.default ];

        disko.devices.disk.main = {
          device = disk-device;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                label = "boot";
                name = "ESP";
                size = "512M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "defaults" ];
                };
              };
              luks = {
                size = "100%";
                label = "luks";
                content = {
                  type = "luks";
                  name = "cryptroot";
                  passwordFile = "/tmp/secret.key";
                  extraOpenArgs = [
                    "--allow-discards"
                    "--perf-no_read_workqueue"
                    "--perf-no_write_workqueue"
                  ];
                  settings.crypttabExtraOpts = [
                    "tpm2-device=auto"
                    "fido2-device=auto"
                    "token-timeout=10"
                  ];
                  content = {
                    type = "btrfs";
                    extraArgs = [
                      "-L"
                      "nixos"
                      "-f"
                    ];
                    postCreateHook = ''
                      mount -t btrfs /dev/disk/by-label/nixos /mnt
                      btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
                      btrfs subvolume snapshot -r /mnt/home /mnt/home-blank
                      umount /mnt
                    '';
                  };
                };
              };
            };
          };
        };
      };
  };
}
