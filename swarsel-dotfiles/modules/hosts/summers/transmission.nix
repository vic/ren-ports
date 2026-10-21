# summers-transmission: old hosts/nixos/x86_64-linux/summers/guests/transmission/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-transmission = {
    isImpermanence = true;
  };
  ren.aspects.summers-transmission.at = ren.guest.summers-transmission;
  ren.aspects.summers-transmission.includes = [
    ren.aspects.profile-microvm
    ren.aspects.transmission
  ];
  ren.aspects.summers-transmission.nixos =
    {
      variant,
      lib,
      ...
    }:
    {
      imports = [

      ];

      swarselsystems = {
        isMicroVM = true;
      };

    }
    // lib.optionalAttrs (!variant.minimal) {

      microvm = {
        mem = 1024 * 6;
        vcpu = 6;
      };

    };
}
