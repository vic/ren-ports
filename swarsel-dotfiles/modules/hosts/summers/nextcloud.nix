# summers-nextcloud: old hosts/nixos/x86_64-linux/summers/guests/nextcloud/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-nextcloud = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-nextcloud.at = ren.guest.summers-nextcloud;
  ren.aspects.summers-nextcloud.includes = [
    ren.aspects.nextcloud
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-nextcloud.nixos =
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
        vcpu = 2;
      };

    };
}
