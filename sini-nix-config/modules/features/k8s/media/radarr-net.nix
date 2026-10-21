# radarr CNPs: gateway-ingress, media-pg-egress, internet-egress (world 80/443: Servarr metadata API + artwork).
{ ... }:
{
  ren.aspects.k8s-media-radarr.k8s-manifests =
    { ... }:
    {
      applications.radarr.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-radarr.spec = {
          description = "Allow Envoy Gateway proxies to reach radarr.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "radarr";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "7878";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-postgres-egress-radarr.spec = {
          description = "Allow radarr to reach the media-pg CNPG cluster.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "radarr";
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

        allow-internet-egress-radarr.spec = {
          description = "Allow radarr to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "radarr";
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
