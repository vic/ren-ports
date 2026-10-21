# ZFS single-disk layout: datasets.
{ ... }:
{
  ren.aspects.disk-zfs-disk-single.nixos =
    let
      emptySnapshot =
        name: "zfs list -t snapshot -H -o name | grep -E '^${name}@empty$' || zfs snapshot ${name}@empty";
    in
    {
      disko.devices.zpool.zroot.datasets = {
      "reserved" = {
        type = "zfs_fs";
        options = {
          mountpoint = "none";
          canmount = "off";
          reservation = "10G";
          "com.sun:auto-snapshot" = "false";
        };
      };
      "local/root" = {
        mountpoint = "/";
        type = "zfs_fs";
        options.mountpoint = "legacy";
        postCreateHook = ''
          zfs snapshot zroot/local/root@empty;
          zfs snapshot zroot/local/root@lastboot;
        '';
      };
      "local/nix" = {
        type = "zfs_fs";
        options.mountpoint = "legacy";
        mountpoint = "/nix";
        options = {
          atime = "off";
          canmount = "on";
          compression = "zstd";
          "com.sun:auto-snapshot" = "true";
        };
        postCreateHook = emptySnapshot "zroot/local/nix";
      };
      "local/home" = {
        type = "zfs_fs";
        options.mountpoint = "legacy";
        mountpoint = "/home";
        options."com.sun:auto-snapshot" = "true";
        postCreateHook = ''
          zfs snapshot zroot/local/home@empty;
          zfs snapshot zroot/local/home@lastboot
        '';
      };
      "local/persist" = {
        type = "zfs_fs";
        options.mountpoint = "legacy";
        mountpoint = "/persist";
        options."com.sun:auto-snapshot" = "true";
        postCreateHook = emptySnapshot "zroot/local/persist";
      };
      "local/cache" = {
        type = "zfs_fs";
        options.mountpoint = "legacy";
        mountpoint = "/cache";
        options."com.sun:auto-snapshot" = "true";
        postCreateHook = emptySnapshot "zroot/local/cache";
      };
      "local/containers" = {
        type = "zfs_fs";
        mountpoint = "/cache/var/lib/containers";
        options = {
          mountpoint = "legacy";
          atime = "off";
          recordsize = "128K";
          "com.sun:auto-snapshot" = "true";
        };
        postCreateHook = emptySnapshot "zroot/local/containers";
      };
      # containerd data root (k3s nodes): content store + metadata,
      # persisted across the impermanence wipe. New on already-deployed
      # pools, so provision-zfs-datasets (above) creates it pre-mount.
      "local/containerd" = {
        type = "zfs_fs";
        mountpoint = "/var/lib/containerd";
        options = {
          mountpoint = "legacy";
          atime = "off";
          recordsize = "128K";
          "com.sun:auto-snapshot" = "true";
        };
        postCreateHook = emptySnapshot "zroot/local/containerd";
      };
      # The zfs snapshotter requires its root to BE a zfs dataset
      # mountpoint (not merely on a zfs fs), so it gets a dedicated child
      # dataset at exactly the plugin path. The snapshotter creates a CoW
      # child dataset per image layer under it — don't auto-snapshot that
      # churn.
      "local/containerd/snapshotter" = {
        type = "zfs_fs";
        mountpoint = "/var/lib/containerd/io.containerd.snapshotter.v1.zfs";
        options = {
          mountpoint = "legacy";
          atime = "off";
          recordsize = "128K";
          "com.sun:auto-snapshot" = "false";
        };
      };
      "local/libvirt-images" = {
        type = "zfs_fs";
        mountpoint = "/persist/var/lib/libvirt/images";
        options = {
          mountpoint = "legacy";
          atime = "off";
          recordsize = "64K";
          compression = "lz4";
          "com.sun:auto-snapshot" = "true";
        };
        postCreateHook = emptySnapshot "zroot/local/libvirt-images";
      };
      };
    };
}
