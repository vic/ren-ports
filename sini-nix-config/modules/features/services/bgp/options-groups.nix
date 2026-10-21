# services.bgp.peerGroups option. addressFamilies: options-af.nix.
{ lib, ... }:
{
  ren.aspects.svc-bgp.nixos.options.services.bgp = {
    peerGroups = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            remoteAs = lib.mkOption {
              type = lib.types.int;
              description = "Remote AS for peer group";
            };
            updateSource = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Update source interface";
            };
            ebgpMultihop = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "EBGP multihop distance";
            };
            softReconfiguration = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable soft reconfiguration inbound";
            };
            listenRange = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "BGP listen range for peer group";
            };
          };
        }
      );
      default = { };
      description = "BGP peer groups";
    };
  };
}
