# summers-kanidm: old hosts/nixos/x86_64-linux/summers/guests/kanidm/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-kanidm = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-kanidm.at = ren.guest.summers-kanidm;
  ren.aspects.summers-kanidm.includes = [
    ren.aspects.kanidm
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-kanidm.nixos =
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
        mem = 1024 * 4;
        vcpu = 2;
      };

    };
}
