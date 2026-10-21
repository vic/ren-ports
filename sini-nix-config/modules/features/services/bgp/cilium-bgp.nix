# Cilium BGP, FRR peering with cilium for pod/service/LB route advertisement.
# Config half: cilium-bgp-config.nix.
{ ren, lib, ... }:
{
  ren.kinds.machine.svc-bgp-cilium-bgp = ren.lib.opt (lib.types.submodule {
    options = {
      localAsn = lib.mkOption {
        type = lib.types.int;
        default = 65002;
        description = "Cilium BGP AS number for this node";
      };
      peerWithGateway = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to also peer directly with the environment gateway (Unifi router), advertising the same loadbalancer routes as to the hub";
      };
    };
  }) { };

  ren.aspects.svc-bgp-cilium-bgp.includes = with ren.aspects; [ svc-bgp ];
}
