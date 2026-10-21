# summers-atuin: old hosts/nixos/x86_64-linux/summers/guests/atuin/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-atuin = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-atuin.at = ren.guest.summers-atuin;
  ren.aspects.summers-atuin.includes = [
    ren.aspects.atuin
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-atuin.nixos =
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
