# NOT IN USE. Nothing imports this file, and the `_` prefix keeps den's import-tree
#  from picking it up on its own (see the import-tree setup). The machine was taken over in
#  place with `nixos-rebuild switch`, so its disk is whatever the manual install left:
#  an MBR-labelled /dev/sda with one ext4 partition, described in ./_hardware.nix.
#
# This is kept because the day a work VM is rebuilt from nothing — nixos-anywhere, a
#  new VM, a restored Proxmox host — the layout should not have to be reinvented. To
#  use it, add back to ./default.nix's `nixos` imports:
#
#    inputs.omniflake.unified.disko.nixosModules.disko
#    ./_disko.nix
#
#  and drop the `fileSystems."/"` block from ./_hardware.nix, which disko then
#  generates. Note that `disko --mode disko` *wipes* /dev/sda; it is an install-time
#  tool, not something to apply to the running machine.
#
# Matches the Proxmox VM as configured: SeaBIOS + a single VirtIO SCSI disk (scsi0),
#  which the guest sees as /dev/sda. GPT rather than MBR so the layout is the same shape
#  as mensa-nixos', which means a 1 MiB EF02 partition for GRUB's core image — with
#  SeaBIOS there is no ESP and nothing is mounted at /boot/efi. Switching to this layout
#  therefore also means dropping the `boot.loader.grub.device = "/dev/sda"` override in
#  ./default.nix: the EF02 partition adds /dev/sda to grub.devices by itself, and naming
#  it twice trips "You cannot have duplicated devices in mirroredBoots".
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        # GRUB's core.img lives here on BIOS/GPT. Not a filesystem, never mounted.
        bios-boot = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };

        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            # discard: the VM disk is thin-provisioned, so freed blocks should be
            #  returned to the Proxmox storage (needs discard=on on the disk too).
            mountOptions = [ "defaults" ];
            extraArgs = [
              "-L"
              "nixos"
            ];
          };
        };
      };
    };
  };
}
