# sonarr CNPs: gateway-ingress, media-pg-egress, internet-egress (world 80/443: Servarr metadata API + artwork).
{ ... }:
{
  ren.aspects.k8s-media-sonarr.k8s-manifests =
    { ... }:
    {
      applications.sonarr.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-sonarr.spec = {
          description = "Allow Envoy Gateway proxies to reach sonarr.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "sonarr";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "8989";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-postgres-egress-sonarr.spec = {
          description = "Allow sonarr to reach the media-pg CNPG cluster.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "sonarr";
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

        allow-internet-egress-sonarr.spec = {
          description = "Allow sonarr to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "sonarr";
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
