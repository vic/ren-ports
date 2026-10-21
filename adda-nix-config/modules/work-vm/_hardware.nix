{ lib, ... }:
{
  # There is no scan-the-hardware step for these hosts: they are VMs, and the virtio
  #  driver set comes from addax.virtualisation.proxmoxGuest. What is left is the things
  #  only the machine knows, taken from the /etc/nixos/hardware-configuration.nix that
  #  nixos-generate-config wrote during fabrica-nixos' manual install.
  #
  # Shared by every host including addax.workVM, which is correct only as long as they
  #  stay block-level Proxmox clones of that disk: a clone copies the ext4 superblock,
  #  so the filesystem UUID below is the same on all of them. Check with
  #  `blkid /dev/sda1` after cloning; if a VM ever gets a freshly created filesystem,
  #  this file has to move back next to that host.
  #
  # The disk is adopted as-is rather than repartitioned: this flake takes the machine
  #  over with `nixos-rebuild switch`, not with an installer, so /dev/sda keeps the MBR
  #  ("dos") label and the single 200 GiB ext4 partition it already has. A disko layout
  #  for it can be written later, but it is only usable on a reinstall, since
  #  `disko --mode disko` wipes the device it describes.
  #
  # Verified on the running machine (2026-10-03): `lsblk` reports sda 200G, PTTYPE dos,
  #  sda1 ext4 mounted at /; /sys/firmware/efi does not exist, i.e. SeaBIOS, no ESP, and
  #  nothing to mount at /boot/efi.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/35afdedb-4cf0-4b54-98da-727d10606ebf";
    fsType = "ext4";
  };

  # No swap partition and no swap file: addax.swap.zram supplies the swap for this host.
  swapDevices = [ ];

  # One virtio NIC, ens18, on the office LAN via DHCP. Named per-interface nowhere
  #  because NetworkManager (modules/defaults.nix) is what actually runs the lease.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
