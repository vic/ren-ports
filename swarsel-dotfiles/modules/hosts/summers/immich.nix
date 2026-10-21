# summers-immich: old hosts/nixos/x86_64-linux/summers/guests/immich/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-immich = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-immich.at = ren.guest.summers-immich;
  ren.aspects.summers-immich.includes = [
    ren.aspects.immich
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-immich.nixos =
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
        mem = 1024 * 16;
        vcpu = 14;
      };

    };
}
