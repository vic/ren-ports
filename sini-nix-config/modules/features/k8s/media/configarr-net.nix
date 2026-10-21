# Configarr CNPs: egress to the four arr APIs and world 443 (TRaSH guides + recyclarr templates
# are fetched from GitHub on each run). Plain CNPs, no helper baselines.
{ ... }:
{
  ren.aspects.k8s-media-configarr.k8s-manifests =
    { ... }:
    let
      podSelector.matchLabels."app.kubernetes.io/name" = "configarr";
      arrEgress = svc: port: {
        toEndpoints = [
          { matchLabels."app.kubernetes.io/name" = svc; }
        ];
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
      applications.configarr.resources.ciliumNetworkPolicies = {
        "allow-arr-egress-configarr".spec = {
          description = "Allow configarr to reach the sonarr/radarr/lidarr/whisparr APIs.";
          endpointSelector = podSelector;
          egress = [
            (arrEgress "sonarr" 8989)
            (arrEgress "radarr" 7878)
            (arrEgress "lidarr" 8686)
            (arrEgress "whisparr" 6969)
          ];
        };

        "allow-internet-egress-configarr".spec = {
          description = "Allow configarr to fetch the TRaSH/recyclarr config templates over HTTPS.";
          endpointSelector = podSelector;
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
