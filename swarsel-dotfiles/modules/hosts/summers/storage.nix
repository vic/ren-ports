# summers-storage: old hosts/nixos/x86_64-linux/summers/guests/storage/default.nix
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
in
{
  ren.guest.summers-storage = {
    isImpermanence = true;
    nodeRoles = [ "homeSyncthingServer" ];
    proxyHost = "twothreetunnel";
  };
  ren.aspects.summers-storage.at = ren.guest.summers-storage;
  ren.aspects.summers-storage.includes = [
    ren.aspects.nfs
    ren.aspects.profile-microvm
    ren.aspects.server-syncthing
  ];
  ren.aspects.summers-storage.nixos =
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
        mem = 1024 * 4;
        vcpu = 2;
      };

    };
}
