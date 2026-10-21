# prowlarr CNPs: gateway-ingress, media-pg-egress, internet-egress (world 80/443: indexer searches + Cardigann definitions fetch; without it every search fails).
{ ... }:
{
  ren.aspects.k8s-media-prowlarr.k8s-manifests =
    { ... }:
    {
      applications.prowlarr.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-prowlarr.spec = {
          description = "Allow Envoy Gateway proxies to reach prowlarr.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "prowlarr";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "9696";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-postgres-egress-prowlarr.spec = {
          description = "Allow prowlarr to reach the media-pg CNPG cluster.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "prowlarr";
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

        allow-internet-egress-prowlarr.spec = {
          description = "Allow prowlarr to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "prowlarr";
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
