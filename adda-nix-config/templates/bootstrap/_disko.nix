# Keep as plain NixOS module so that CLI disko can use the file directly.
{
  disko.devices = {
    disk = {
      # Primary drive (fast SSD/NVMe).
      ssd-256gb = {
        type = "disk";
        device = "/dev/vda"; # TODO: Replace with your fast drive name.
        content = {
          type = "gpt";
          partitions = {
            # 1. BIOS Boot Partition (for legacy BIOS / CSM boot).
            bios-boot = {
              size = "64M";
              type = "EF02"; # The GUID setting the `bios_grub` flag.
              priority = 1;
            };

            # 2. EFI System Partition (ESP) for UEFI boot.
            esp = {
              size = "2G";
              type = "EF00"; # The GUID setting the `boot` and `esp` flags.
              priority = 2;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
                mountOptions = [ "umask=0077" ];
              };
            };

            # 3. Primary LVM physical disk.
            primary = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool-ssd";
              };
            };
          };
        };
      };

      # Secondary data drive (slow HDD).
      hdd-1tb = {
        type = "disk";
        device = "/dev/vdb"; # TODO: Replace with your actual HDD drive name.
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool-hdd";
              };
            };
          };
        };
      };
    };

    # LVM Volume Group definition.
    lvm_vg = {
      pool-ssd = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              # mountOptions = [
              #   "defaults"
              # ];
              extraArgs = [ "-f" ]; # Force format.
              subvolumes = {
                # 1. The root system.
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" ];
                };

                # The Nix store (fast compilation and caching).
                # Nix handles its own rollbacks: If one ever restores the root filesystem from a snapshot, you DO NOT want
                #  to roll back /nix.
                "/nix" = {
                  mountpoint = "/nix";
                  # `noatime` is highly recommended for /nix to improve build performance.
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };

                # The TMP.
                # Excluding TMP files from snapshots.
                "/tmp" = {
                  mountpoint = "/tmp";
                  # `nodatacow` is great for heavy write-churn directories like `/tmp`.
                  # `nodatacow` automatically disables compression for this subvolume.
                  mountOptions = [
                    "noatime"
                    "nodatacow"
                  ];
                };

                # User configuration and fast local files.
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" ];
                };
              };
            };
          };

          # root = {
          #   size = "100%FREE";
          #   content = {
          #     type = "filesystem";
          #     format = "ext4";
          #     mountpoint = "/";
          #   };
          # };
          # home = {
          #   size = "100%FREE";
          #   content = {
          #     type = "filesystem";
          #     format = "ext4";
          #     mountpoint = "/home";
          #   };
          # };
        };
      };
      pool-hdd = {
        type = "lvm_vg";
        lvs = {
          data = {
            size = "100%FREE";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                # A single subvolume for your bulk data.
                "/data" = {
                  mountpoint = "/mnt/data";
                  # `noatime` is good for HDDs to reduce unnecessary disk writes.
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
          # home = {
          #   size = "100%FREE";
          #   content = {
          #     type = "filesystem";
          #     format = "ext4";
          #     mountpoint = "/home";
          #   };
          # };
        };
      };
    };
  };
}
