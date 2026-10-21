# summers-ankisync: old hosts/nixos/x86_64-linux/summers/guests/ankisync/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-ankisync = {
    isImpermanence = true;
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-ankisync.at = ren.guest.summers-ankisync;
  ren.aspects.summers-ankisync.includes = [
    ren.aspects.ankisync
    ren.aspects.invidious-companion
    ren.aspects.profile-microvm
    ren.aspects.socks-proxy
  ];
  ren.aspects.summers-ankisync.nixos =
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
