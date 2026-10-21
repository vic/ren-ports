{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "ohci_pci"
    "ehci_pci"
    "pata_atiixp"
    "xhci_pci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];

  #boot.initrd.availableKernelModules = [
  #  "nvme"
  #  "thunderbolt"
  #  "usbhid"
  #  "uas"
  #];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  # boot.extraModulePackages = [ ];

  # fileSystems."/" = {
  #   device = "/dev/mapper/ssd-root";
  #   fsType = "btrfs";
  # };
  # fileSystems."/mnt/data" = {
  #   device = "/dev/mapper/ssd-root";
  #   fsType = "btrfs";
  # };

  # fileSystems."/boot/efi" = {
  #   device = "/dev/disk/by-uuid/ADCA-06F2";
  #   fsType = "vfat";
  #   options = [
  #     "fmask=0022"
  #     "dmask=0022"
  #   ];
  # };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp102s0f3u1u1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp1s0f0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
