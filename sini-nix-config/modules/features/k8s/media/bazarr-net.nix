# Bazarr CNPs: gateway-ingress, media-pg-egress, internet-egress.
{ ... }:
{
  ren.aspects.k8s-media-bazarr.k8s-manifests =
    { ... }:
    {
      applications.bazarr.resources = {
        ciliumNetworkPolicies = {
          allow-gateway-ingress-bazarr.spec = {
            description = "Allow Envoy Gateway proxies to reach bazarr.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "bazarr";
            ingress = [
              {
                fromEndpoints = [
                  { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
                ];
                toPorts = [
                  {
                    ports = [
                      {
                        port = "6767";
                        protocol = "TCP";
                      }
                    ];
                  }
                ];
              }
            ];
          };

          allow-postgres-egress-bazarr.spec = {
            description = "Allow bazarr to reach the media-pg CNPG cluster.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "bazarr";
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

          # World egress (80/443): subtitle providers (opensubtitles et al) are direct world calls.
          allow-internet-egress-bazarr.spec = {
            description = "Allow bazarr to reach the public internet.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "bazarr";
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
    };
}
