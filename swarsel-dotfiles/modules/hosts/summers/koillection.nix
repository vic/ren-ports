# summers-koillection: old hosts/nixos/x86_64-linux/summers/guests/koillection/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-koillection = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-koillection.at = ren.guest.summers-koillection;
  ren.aspects.summers-koillection.includes = [
    ren.aspects.koillection
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-koillection.nixos =
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
