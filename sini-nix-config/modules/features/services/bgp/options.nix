# services.bgp options (scalars + neighbors). Group/AF options: options-groups.nix.
{ lib, ... }:
{
  ren.aspects.svc-bgp.nixos.options.services.bgp = {
    staticRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Static IP routes";
    };

    prefixLists = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "IP prefix lists";
    };

    routeMaps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Route map configurations";
    };

    maximumPaths = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Maximum number of BGP paths";
    };

    extraConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Extra BGP configuration";
    };

    neighbors = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            ip = lib.mkOption {
              type = lib.types.str;
              description = "Neighbor IP address";
            };
            asn = lib.mkOption {
              type = lib.types.int;
              description = "Neighbor AS number";
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
            routeMapIn = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Inbound route map";
            };
            routeMapOut = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Outbound route map";
            };
            allowasIn = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Allow AS in path";
            };
          };
        }
      );
      default = [ ];
      description = "BGP neighbors";
    };
  };
}
