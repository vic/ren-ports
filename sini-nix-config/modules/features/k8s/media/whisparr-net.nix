# whisparr CNPs: gateway-ingress, media-pg-egress, internet-egress (world 80/443: Servarr metadata API + artwork).
{ ... }:
{
  ren.aspects.k8s-media-whisparr.k8s-manifests =
    { ... }:
    {
      applications.whisparr.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-whisparr.spec = {
          description = "Allow Envoy Gateway proxies to reach whisparr.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "whisparr";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "6969";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-postgres-egress-whisparr.spec = {
          description = "Allow whisparr to reach the media-pg CNPG cluster.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "whisparr";
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

        allow-internet-egress-whisparr.spec = {
          description = "Allow whisparr to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "whisparr";
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
