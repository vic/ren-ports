# Glance CNPs: gateway-ingress, internet-egress (80/443: Jellyfin external URL + simple-icons CDN),
# and in-namespace API egress to the monitored services (mirror of the dashboard ingress allows
# in network-policy.nix). DNS is coredns.nix's cluster-wide egress grant.
{ ... }:
{
  ren.aspects.k8s-media-glance.k8s-manifests =
    { ... }:
    let
      apiEgress = svc: port: {
        toEndpoints = [ { matchLabels."app.kubernetes.io/name" = svc; } ];
        toPorts = [
          {
            ports = [
              {
                port = toString port;
                protocol = "TCP";
              }
            ];
          }
        ];
      };
    in
    {
      applications.glance.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-glance.spec = {
          description = "Allow Envoy Gateway proxies to reach glance.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "glance";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "8080";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-internet-egress-glance.spec = {
          description = "Allow glance to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "glance";
          egress = [
            {
              toEntities = [ "world" ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "80";
                      protocol = "TCP";
                    }
                    {
                      port = "443";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-api-egress-glance.spec = {
          description = "Allow glance to reach the in-namespace media APIs it monitors.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "glance";
          egress = [
            (apiEgress "lidarr" 8686)
            (apiEgress "radarr" 7878)
            (apiEgress "sabnzbd" 8080)
            (apiEgress "sonarr" 8989)
            (apiEgress "whisparr" 6969)
          ];
        };
      };
    };
}
