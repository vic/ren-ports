# BGP hub, uplink role with auto-discovery of spoke hosts and gateway peering.
{ ren, lib, ... }:
{
  ren.kinds.machine.svc-bgp-hub = ren.lib.opt (lib.types.submodule {
    options = {
      maximumPaths = lib.mkOption {
        type = lib.types.int;
        default = 8;
        description = "Maximum number of BGP paths";
      };
      peerWithGateway = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to automatically peer with the environment gateway (Unifi router)";
      };
      defaultOriginateToSpokes = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to originate default route to spoke neighbors";
      };
    };
  }) { };

  ren.aspects.svc-bgp-hub = {
    includes = with ren.aspects; [ svc-bgp ];

    nixos =
      { environment, host, bgp-peers, ... }:
      let
        hubSettings = host.svc-bgp-hub;
        inherit (environment.networks.default) gatewayIp;
        gatewayNeighbor = lib.optional hubSettings.peerWithGateway {
          ip = gatewayIp;
          asn = environment.networks.default.gatewayAsn;
        };

        # Auto-discovered spoke peers, not self (same-environment scoping guaranteed by bgp-peers channel)
        spokeNeighbors = map (p: { inherit (p) ip asn; }) (
          lib.filter (p: p.hostname != host.name) bgp-peers
        );

        allNeighbors = gatewayNeighbor ++ spokeNeighbors;

        addressFamilyNeighbors = lib.listToAttrs (
          map (neighbor: {
            name = neighbor.ip;
            value = {
              activate = true;
              nextHopSelf = false;
              defaultOriginate =
                if neighbor.ip == gatewayIp then false else hubSettings.defaultOriginateToSpokes;
            };
          }) allNeighbors
        );
      in
      {
        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = lib.mkDefault 1;
          "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
        };

        services.bgp = {
          inherit (hubSettings) maximumPaths;
          neighbors = allNeighbors;
          addressFamilies.ipv4-unicast.neighbors = addressFamilyNeighbors;
        };
      };
  };
}
