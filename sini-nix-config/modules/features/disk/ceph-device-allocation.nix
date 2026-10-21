# Declares the Ceph OSD device path for this host, consumed by rook-ceph.
{ ren, lib, ... }:
{
  ren.kinds.machine.disk-ceph-device-allocation = ren.lib.opt (lib.types.submodule {
    options.device = lib.mkOption {
      type = lib.types.str;
      description = "Full device path for Ceph OSD (e.g., /dev/disk/by-id/nvme-...).";
    };
  }) { };

  ren.aspects.disk-ceph-device-allocation = { };
}
