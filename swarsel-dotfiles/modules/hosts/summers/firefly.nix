# summers-firefly: old hosts/nixos/x86_64-linux/summers/guests/firefly/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-firefly = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-firefly.at = ren.guest.summers-firefly;
  ren.aspects.summers-firefly.includes = [
    ren.aspects.firefly-iii
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-firefly.nixos =
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
