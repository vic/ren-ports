# ZFS single-disk disko layout: disk + pool. Datasets in zfs-disk-single-datasets.nix, mounts in -fs.nix.
# Retired provision-zfs-datasets rollout unit (commented in den) dropped; see sini git history.
{ ren, lib, inputs, ... }:
{
  ren.kinds.machine.disk-zfs-disk-single = ren.lib.opt (lib.types.submodule {
    options.device_id = lib.mkOption {
      type = lib.types.str;
      description = "Disk device path for ZFS pool (e.g., /dev/disk/by-id/nvme-...)";
    };
  }) { };

  ren.aspects.disk-zfs-disk-single = {
    includes = with ren.aspects; [ disk-zfs-disk-single-root ];

    nixos =
      { host, ... }:
      {
        imports = [ inputs.disko.nixosModules.default ];

        disko.devices = {
          disk.disk0 = {
            type = "disk";
            device = host.disk-zfs-disk-single.device_id;
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  type = "EF00";
                  size = "500M";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=077" ];
                  };
                };
                root = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "zroot";
                  };
                };
              };
            };
          };
          zpool.zroot = {
            type = "zpool";
            options = {
              ashift = "12";
              autotrim = "on";
            };

            rootFsOptions = {
              acltype = "posixacl";
              canmount = "off";
              # blake3 over edonr: OpenZFS ships no SIMD implementation of edonr
              # at all, so it runs scalar everywhere, while blake3 has avx2 and
              # avx512 paths. Every host in the fleet has at least avx2, which is
              # the crossover (measured on cortex, 64k blocks: edonr 2325 MB/s,
              # blake3-avx2 3831, blake3-avx512 8552; blake3 loses below avx2).
              # Encryption does not bypass it — an encrypted block's checksum is
              # 128 bits of this algorithm plus 128 bits of AEAD MAC.
              # Note the pool feature is not read-only compatible: once a blake3
              # block is written the pool needs OpenZFS >= 2.2 to import at all,
              # so rescue media older than that stops working.
              checksum = "blake3";
              compression = "zstd";
              dnodesize = "auto";
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///tmp/secret.key";
              mountpoint = "none";
              # Byte-exact filenames, as on every other Linux filesystem. Any
              # normalization other than "none" forces utf8only=on, and utf8only
              # makes the kernel reject filenames that are not valid UTF-8 with
              # EILSEQ instead of creating them: package test suites that build
              # such names fail (python pygit2), and OCI layers carrying them
              # fail to unpack. formD additionally makes lookups
              # normalization-insensitive, so NFC and NFD spellings of one name
              # collide and a tree containing both cannot be checked out.
              # Both are create-time only and cannot be set on zfs receive, so
              # getting this wrong costs a dataset rebuild.
              normalization = "none";
              utf8only = "off";
              relatime = "on";
              xattr = "sa";
              "com.sun:auto-snapshot" = "false";
            };

            postCreateHook = ''
              zfs set keylocation="prompt" $name;
              if ! zfs list -t snap zroot/local/root@empty; then
                  zfs snapshot zroot/local/root@empty
              fi
            '';
          };
        };
      };
  };
}
