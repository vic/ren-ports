# summers-homebox: old hosts/nixos/x86_64-linux/summers/guests/homebox/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-homebox = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-homebox.at = ren.guest.summers-homebox;
  ren.aspects.summers-homebox.includes = [
    ren.aspects.homebox
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-homebox.nixos =
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
