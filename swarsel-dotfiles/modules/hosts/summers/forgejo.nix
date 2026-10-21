# summers-forgejo: old hosts/nixos/x86_64-linux/summers/guests/forgejo/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-forgejo = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-forgejo.at = ren.guest.summers-forgejo;
  ren.aspects.summers-forgejo.includes = [
    ren.aspects.forgejo
    ren.aspects.profile-microvm
  ];
  ren.aspects.summers-forgejo.nixos =
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
