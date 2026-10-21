# summers-paperless: old hosts/nixos/x86_64-linux/summers/guests/paperless/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-paperless = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-paperless.at = ren.guest.summers-paperless;
  ren.aspects.summers-paperless.includes = [
    ren.aspects.paperless
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-paperless.nixos =
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
        mem = 1024 * 8;
        vcpu = 4;
      };

    };
}
