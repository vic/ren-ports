# profilarr CNPs: gateway-ingress, arr-egress (sonarr/radarr only; Dictionarry does not drive lidarr/whisparr),
# internet-egress (443: git clone of the Dictionarry database).
{ ... }:
{
  ren.aspects.k8s-media-profilarr.k8s-manifests =
    { ... }:
    {
      applications.profilarr.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-profilarr.spec = {
          description = "Allow Envoy Gateway proxies to reach profilarr.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "profilarr";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "6868";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-arr-egress-profilarr.spec = {
          description = "Allow profilarr to reach the sonarr/radarr APIs.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "profilarr";
          egress = [
            {
              toEndpoints = [ { matchLabels."app.kubernetes.io/name" = "sonarr"; } ];
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
            {
              toEndpoints = [ { matchLabels."app.kubernetes.io/name" = "radarr"; } ];
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

        allow-internet-egress-profilarr.spec = {
          description = "Allow profilarr to git-clone the Dictionarry database over HTTPS.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "profilarr";
          egress = [
            {
              toEntities = [ "world" ];
              toPorts = [
                {
                  ports = [
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
