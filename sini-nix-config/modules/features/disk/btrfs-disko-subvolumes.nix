# btrfs-disko subvolumes (zstd:1 ssd opts) and neededForBoot mounts.
{ lib, ... }:
{
  ren.aspects.disk-btrfs-disko.nixos =
    { host, ... }:
    let
      opts = [
        "defaults"
        "compress=zstd:1"
        "ssd"
        "discard=async"
        "noatime"
        "nodiratime"
      ];
      mount = mountpoint: {
        inherit mountpoint;
        mountOptions = opts;
      };
    in
    {
      disko.devices.disk.main.content.partitions.luks.content.content.subvolumes = {
        "/root" = mount "/";
        "/home" = mount "/home";
        "/nix" = mount "/nix";
        "/persist" = mount "/persist";
        "/cache" = mount "/cache";
      }
      // lib.optionalAttrs (host.disk-btrfs-disko.swap_size > 0) {
        "@swap" = {
          mountpoint = "/swap";
          swap.swapfile.size = "${toString host.disk-btrfs-disko.swap_size}M";
        };
      };
      fileSystems = {
        "/nix".neededForBoot = true;
        "/home".neededForBoot = true;
        "/persist".neededForBoot = true;
        "/cache".neededForBoot = true;
      };
    };
}
