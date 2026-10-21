# summers-freshrss: old hosts/nixos/x86_64-linux/summers/guests/freshrss/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-freshrss = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-freshrss.at = ren.guest.summers-freshrss;
  ren.aspects.summers-freshrss.includes = [
    ren.aspects.freshrss
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-freshrss.nixos =
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
        mem = 1024 * 3;
        vcpu = 1;
      };

    };
}
