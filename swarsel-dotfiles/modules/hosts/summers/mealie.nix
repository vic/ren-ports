# summers-mealie: old hosts/nixos/x86_64-linux/summers/guests/mealie/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-mealie = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-mealie.at = ren.guest.summers-mealie;
  ren.aspects.summers-mealie.includes = [
    ren.aspects.mealie
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-mealie.nixos =
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
        mem = 1024 * 1;
        vcpu = 1;
      };

    };
}
