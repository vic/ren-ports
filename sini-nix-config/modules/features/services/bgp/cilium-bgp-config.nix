# Cilium BGP FRR config: prefix lists, route maps, cilium peer group, uplink + gateway neighbors.
{ ren, lib, ... }:
{
  ren.aspects.svc-bgp-cilium-bgp.nixos =
    { environment, host, bgp-peers, ... }:
    let
      cluster = ren.helpers.clusterOf host;
      ciliumAsn = host.svc-bgp-cilium-bgp.localAsn;
      localAsn = host.svc-bgp.localAsn;

      # In this hub/spoke design spokes share one AS (65001) and the hub sits in a distinct AS
      # (65000), so the hub is the unique peer whose base ASN differs from ours. Spokes peer
      # north/south with the hub only; east/west axon-to-axon routing is handled by OpenFabric.
      hubPeer = lib.findFirst (p: p.asn != localAsn) null (
        lib.filter (p: p.hostname != host.name) bgp-peers
      );
      uplinkIp = if hubPeer != null then hubPeer.ip else null;

      # The gateway gets the hub's northbound policy: loadbalancer routes out, default only in.
      gateway = environment.networks.default;
      gatewayIp = if host.svc-bgp-cilium-bgp.peerWithGateway then gateway.gatewayIp else null;

      # Cluster networks for this host; den's fallback CIDRs when the host is in no cluster.
      podCidr = if cluster != null then cluster.networks.kubernetes-pods.cidr else "172.20.0.0/16";
      serviceCidr =
        if cluster != null then cluster.networks.kubernetes-services.cidr else "172.21.0.0/16";
      loadbalancerCidr =
        if cluster != null then cluster.networks.kubernetes-loadbalancers.cidr else "172.22.0.0/16";

      afNeighbor = {
        activate = true;
        nextHopSelf = false;
      };
    in
    {
      services.bgp = {
        prefixLists = {
          POD-ROUTES = [ "permit ${podCidr} le 32" ];
          SERVICE-ROUTES = [ "permit ${serviceCidr} le 32" ];
          LOADBALANCER-ROUTES = [ "permit ${loadbalancerCidr} le 32" ];
          DEFAULT-ONLY = [ "permit 0.0.0.0/0" ];
        };

        routeMaps = [
          # Only announce loadbalancer IPs to uplink (bgp-hub)
          # Pod and service IPs are only announced across the mesh
          "route-map TO-UPLINK-OUT permit 10"
          "  match ip address prefix-list LOADBALANCER-ROUTES"
          "route-map FROM-UPLINK-IN permit 10"
          "  match ip address prefix-list DEFAULT-ONLY"
        ];

        peerGroups.cilium = {
          remoteAs = ciliumAsn;
          softReconfiguration = true;
          listenRange = "${builtins.head (ren.helpers.ipv4Of host)}/32";
        };

        neighbors =
          lib.optional (uplinkIp != null) {
            ip = uplinkIp;
            inherit (hubPeer) asn;
            routeMapIn = "FROM-UPLINK-IN";
            routeMapOut = "TO-UPLINK-OUT";
          }
          ++ lib.optional (gatewayIp != null) {
            ip = gatewayIp;
            asn = gateway.gatewayAsn;
            routeMapIn = "FROM-UPLINK-IN";
            routeMapOut = "TO-UPLINK-OUT";
          };

        addressFamilies.ipv4-unicast = {
          neighbors =
            lib.optionalAttrs (uplinkIp != null) { ${uplinkIp} = afNeighbor; }
            // lib.optionalAttrs (gatewayIp != null) { ${gatewayIp} = afNeighbor; };
          peerGroups.cilium.activate = true;
        };
      };
    };
}
