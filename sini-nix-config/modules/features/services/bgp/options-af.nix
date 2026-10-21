# services.bgp.addressFamilies option.
{ lib, ... }:
{
  ren.aspects.svc-bgp.nixos.options.services.bgp = {
    addressFamilies = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            networks = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Networks to advertise";
            };
            neighbors = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    activate = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Activate neighbor for this address family";
                    };
                    nextHopSelf = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Set next-hop-self for neighbor";
                    };
                    defaultOriginate = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Send default route to this neighbor";
                    };
                  };
                }
              );
              default = { };
              description = "Per-neighbor address family settings";
            };
            peerGroups = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    activate = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Activate peer group for this address family";
                    };
                    nextHopSelf = lib.mkOption {
                      type = lib.types.bool;
                      default = false;
                      description = "Set next-hop-self for peer group";
                    };
                  };
                }
              );
              default = { };
              description = "Per-peer-group address family settings";
            };
          };
        }
      );
      default = { };
      description = "BGP address family configurations";
    };
  };
}
