# virtualisation: NixOS guest on a Proxmox VE host
{ ren, ... }:
{
  # A NixOS guest on a Proxmox VE host (QEMU/KVM). Everything here is either a paravirtualised driver the installer needs,
  # a channel back to the hypervisor, or hardware/firmware settings that only matter on bare metal.
  #
  # Two settings have Proxmox-side counterparts and do nothing without them:
  #  - `qm set <vmid> --agent enabled=1,fstrim_cloned_disks=1` for the guest agent;
  #  - `qm set <vmid> --serial0 socket` for the serial console below.
  # Discard/TRIM likewise needs `discard=on` (and `ssd=1` for thin-provisioned LVM or ZFS) on the disk itself; the guest
  # side, services.fstrim, is already on by default.
  ren.aspects.virtualisation-proxmoxGuest.nixos =
    {
      lib,
      modulesPath,
      ...
    }:
    {
      # virtio_blk/virtio_scsi/virtio_net in the initrd; without these the installed system cannot find its own root
      # device, whichever bus the VM uses. Also virtio_balloon (memory the host can reclaim) and virtio_rng (entropy
      # without waiting on a virtual timer).
      imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

      # Lets the hypervisor read the guest's IP/filesystems, freeze the fs for snapshots, and shut down cleanly instead
      # of pulling the virtual power cord. mkDefault: nixpkgs' own qemu-vm module (what `nix run .#vm-fabrica-nixos`
      # builds) binds this option to virtualisation.qemu.guestAgent.enable and would otherwise collide with it.
      services.qemuGuest.enable = lib.mkDefault true;

      # Console on both the emulated VGA (Proxmox noVNC) and the serial port, so the kernel log and a getty are reachable
      # with `qm terminal` when networking is the thing that is broken. The last console= wins for /dev/console, hence
      # ttyS0 last.
      boot.kernelParams = [
        "console=tty1"
        "console=ttyS0,115200"
      ];

      # The hypervisor suspends the whole VM; a guest that thinks it can suspend itself just stops responding. Same for
      # the lid/power-button handling underneath.
      systemd.targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };
    };
}
