# summers-radicale: old hosts/nixos/x86_64-linux/summers/guests/radicale/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-radicale = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-radicale.at = ren.guest.summers-radicale;
  ren.aspects.summers-radicale.includes = [
    ren.aspects.profile-microvm
    ren.aspects.radicale
  ];
  ren.aspects.summers-radicale.nixos =
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
