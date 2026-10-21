# ZFS root support (packages, kernel params, services). Included by disk-zfs-disk-single.
{ ren, ... }:
{
  ren.aspects.disk-zfs-disk-single-root = {
    includes = with ren.aspects; [ disk-zfs-diff ];

  nixos =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lzop
        pkgs.mbuffer
        pkgs.pv
      ];

      boot = {
        supportedFilesystems.zfs = true;

        zfs = {
          package = config.boot.kernelPackages.zfs_cachyos;
          devNodes = "/dev/disk/by-id/";
          forceImportRoot = true;
          forceImportAll = true;
          requestEncryptionCredentials = [ "zroot" ];
        };

        kernelParams = [
          "zfs.zfs_arc_max=${toString (16 * 1024 * 1024 * 1024)}"
          # Cloning a range whose source blocks are still dirty makes
          # zfs_clone_range() wait on a full txg sync and retry
          # (module/zfs/zfs_vnops.c: the EAGAIN arm calling
          # txg_wait_synced_flags). Nix and coreutils >= 9 reach that path
          # constantly via copy_file_range, so on a busy pool every writer on
          # the host serialises behind one sync and stalls long enough to trip
          # the systemd watchdogs. With the wait off, the clone returns a
          # short range and the caller falls back to a plain copy; cloning
          # still applies to blocks that are already on disk.
          "zfs.zfs_bclone_wait_dirty=0"
          # TODO: drop once openzfs/zfs#19294 is fixed upstream. On 2.4.4 with a
          # cryptographic checksum (our pools use edonr), the NOP-write path can
          # trip VERIFY(BP_EQUAL(...)) in zio_done during txg sync; the sync
          # thread parks in spl_panic and every ZFS writer then blocks for good.
          # With NOP-writes off, rewriting identical data costs a real write.
          "zfs.zfs_nopwrite_enabled=0"
          # TODO: a deadlock mitigation, not a fix; remove with the line above.
          # A failed ZFS assertion (that bug's VERIFY) parks its thread and
          # wedges the pool for good; this turns it into a kernel panic, which
          # kernel.panic below turns into a reboot, instead of the host hanging
          # until someone power-cycles it. Narrower than hung_task_panic on
          # purpose: the hosts hard-mount NFS, so a NAS outage would leave
          # tasks in D state and reboot them all.
          "spl.spl_panic_halt=1"
          "elevator=none"
          "nohibernate"
        ];
      };

      # TODO: remove with spl_panic_halt above (openzfs/zfs#19294): the panic
      # it raises reboots the host after 10 s.
      boot.kernel.sysctl."kernel.panic" = 10;

      systemd.services.systemd-udev-settle.enable = false;

      services.zfs = {
        expandOnBoot = "all";
        autoScrub.enable = true;
        autoScrub.interval = "weekly";
        trim.enable = true;
      };
    };
  };
}
