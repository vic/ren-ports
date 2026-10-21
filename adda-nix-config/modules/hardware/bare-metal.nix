# hardware: firmware, fwupd and Bluetooth for real silicon
{ ren, ... }:
{
  # Settings that only make sense when the kernel is talking to real silicon: redistributable and unfree firmware blobs,
  # the firmware updater, and the Bluetooth stack. In a VM every one of them is a guaranteed no-op because the hypervisor
  # owns the devices and they cost closure size plus a failing fwupd unit.
  ren.aspects.hardware-bareMetal.nixos = {
    hardware.enableAllFirmware = true;
    hardware.enableRedistributableFirmware = true;

    services.fwupd.enable = true;

    hardware.bluetooth = {
      enable = true;
      #   hsphfpd.enable = true;
      #   settings = {
      #     General = {
      #       enable = "Soure,Sink,Media,Socket";
      #     };
      #   };
    };
    #services.blueman.enable = true;
  };
}
