# hintbooth-adguardhome: old hosts/nixos/x86_64-linux/hintbooth/guests/adguardhome/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.hintbooth-adguardhome = {
    isImpermanence = true;
    nodeRoles = [ "homeDnsServer" ];
    proxyHost = "twothreetunnel";
  };
  ren.aspects.hintbooth-adguardhome.at = ren.guest.hintbooth-adguardhome;
  ren.aspects.hintbooth-adguardhome.includes = [
    ren.aspects.adguardhome
    ren.aspects.microvm-guest-shares
    ren.aspects.profile-microvm
  ];
  ren.aspects.hintbooth-adguardhome.nixos =
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
