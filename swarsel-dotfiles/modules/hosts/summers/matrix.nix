# summers-matrix: old hosts/nixos/x86_64-linux/summers/guests/matrix/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-matrix = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-matrix.at = ren.guest.summers-matrix;
  ren.aspects.summers-matrix.includes = [
    ren.aspects.matrix
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-matrix.nixos =
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
        mem = 1024 * 6;
        vcpu = 2;
      };

    };
}
