# Shoko CNPs: gateway ingress, private-LAN ingress (internal LB), internet egress, AniDB egress.
{ ... }:
{
  ren.aspects.k8s-media-shoko.k8s-manifests =
    { ... }:
    {
      applications.shoko.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-shoko.spec = {
          description = "Allow Envoy Gateway proxies to reach shoko.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "shoko";
          ingress = [
            {
              fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; } ];
              toPorts = [ { ports = [ { port = "8111"; protocol = "TCP"; } ]; } ];
            }
          ];
        };

        # LAN callers reach the internal LoadBalancer, bypassing the OIDC gateway. Whole RFC1918 10/8
        # (portable, not internet-routable, Shoko login in front) also covers the Local source IP and
        # any future node SNAT.
        allow-lan-ingress-shoko.spec = {
          description = "Allow private-LAN clients (e.g. Jellyfin/Shokofin) to reach shoko on 8111, bypassing the OIDC gateway.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "shoko";
          ingress = [
            {
              fromCIDR = [ "10.0.0.0/8" ];
              toPorts = [ { ports = [ { port = "8111"; protocol = "TCP"; } ]; } ];
            }
          ];
        };

        # Artwork/banner CDNs.
        allow-internet-egress-shoko.spec = {
          description = "Allow shoko to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "shoko";
          egress = [
            {
              toEntities = [ "world" ];
              toPorts = [
                {
                  ports = [
                    { port = "80"; protocol = "TCP"; }
                    { port = "443"; protocol = "TCP"; }
                  ];
                }
              ];
            }
          ];
        };

        allow-anidb-egress-shoko.spec = {
          description = "Allow shoko to reach the AniDB UDP (9000, 9002) and HTTP (9001) APIs.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "shoko";
          egress = [
            {
              toEntities = [ "world" ];
              toPorts = [
                {
                  ports = [
                    { port = "9000"; protocol = "UDP"; }
                    { port = "9001"; protocol = "TCP"; }
                    { port = "9002"; protocol = "UDP"; }
                  ];
                }
              ];
            }
          ];
        };
      };
    };
}
