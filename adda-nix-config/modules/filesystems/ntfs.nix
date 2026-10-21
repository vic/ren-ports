# filesystems: read and write NTFS
{ ren, ... }:
{
  # Read/write NTFS, for USB disks and dual-boot Windows partitions. Only machines that have a port someone can plug such
  # a disk into need the driver.
  ren.aspects.filesystems-ntfs.nixos = {
    boot.supportedFilesystems = [
      "ntfs"
    ];
  };
}
