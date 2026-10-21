# lidarr CNPs: gateway-ingress, media-pg-egress, internet-egress (world 80/443: Servarr metadata API + artwork).
{ ... }:
{
  ren.aspects.k8s-media-lidarr.k8s-manifests =
    { ... }:
    {
      applications.lidarr.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-lidarr.spec = {
          description = "Allow Envoy Gateway proxies to reach lidarr.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "lidarr";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "8686";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-postgres-egress-lidarr.spec = {
          description = "Allow lidarr to reach the media-pg CNPG cluster.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "lidarr";
          egress = [
            {
              toEndpoints = [
                { matchLabels."cnpg.io/cluster" = "media-pg"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "5432";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-internet-egress-lidarr.spec = {
          description = "Allow lidarr to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "lidarr";
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
      };
    };
}
