# summers-kavita: old hosts/nixos/x86_64-linux/summers/guests/kavita/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-kavita = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-kavita.at = ren.guest.summers-kavita;
  ren.aspects.summers-kavita.includes = [
    ren.aspects.kavita
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-kavita.nixos =
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
        vcpu = 2;

      };

    };
}
