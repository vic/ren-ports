# Recyclarr CNPs: sonarr/radarr API egress + world 443 (TRaSH guides from GitHub each run).
{ ... }:
{
  ren.aspects.k8s-media-recyclarr.k8s-manifests =
    { ... }:
    {
      applications.recyclarr.resources.ciliumNetworkPolicies = {
        "allow-arr-egress-recyclarr".spec = {
          description = "Allow recyclarr to reach the sonarr/radarr APIs.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "recyclarr";
          egress = [
            {
              toEndpoints = [ { matchLabels."app.kubernetes.io/name" = "sonarr"; } ];
              toPorts = [ { ports = [ { port = "8989"; protocol = "TCP"; } ]; } ];
            }
            {
              toEndpoints = [ { matchLabels."app.kubernetes.io/name" = "radarr"; } ];
              toPorts = [ { ports = [ { port = "7878"; protocol = "TCP"; } ]; } ];
            }
          ];
        };

        "allow-internet-egress-recyclarr".spec = {
          description = "Allow recyclarr to fetch the TRaSH guides over HTTPS.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "recyclarr";
          egress = [
            {
              toEntities = [ "world" ];
              toPorts = [ { ports = [ { port = "443"; protocol = "TCP"; } ]; } ];
            }
          ];
        };
      };
    };
}
