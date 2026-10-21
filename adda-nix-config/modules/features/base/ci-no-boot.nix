# CI: evaluation on CI builds no bootloader and needs no real root device.
{ ren, ... }:
{
  ren.aspects.ci-no-boot = {
    at = ren.lib.and [
      ren.kinds.host
      (ren.lib.when (s: s.fleet.ci))
    ];
    nixos =
      { lib, ... }:
      {
        fileSystems."/".device = lib.mkDefault "/dev/noroot";
        boot.loader.grub.enable = lib.mkDefault false;
      };
  };
}
