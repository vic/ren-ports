# summers-jellyfin: old hosts/nixos/x86_64-linux/summers/guests/jellyfin/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-jellyfin = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-jellyfin.at = ren.guest.summers-jellyfin;
  ren.aspects.summers-jellyfin.includes = [
    ren.aspects.jellyfin
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-jellyfin.nixos =
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
        vcpu = 4;
      };

    };
}
