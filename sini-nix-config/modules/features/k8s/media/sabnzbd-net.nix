# SABnzbd CNPs: gateway ingress, prometheus metrics ingress (9707), internet egress (80/443 + NNTP 119/563).
{ ... }:
{
  ren.aspects.k8s-media-sabnzbd.k8s-manifests =
    { ... }:
    {
      applications.sabnzbd.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-sabnzbd.spec = {
          description = "Allow Envoy Gateway proxies to reach sabnzbd.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "sabnzbd";
          ingress = [
            {
              fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; } ];
              toPorts = [ { ports = [ { port = "8080"; protocol = "TCP"; } ]; } ];
            }
          ];
        };

        allow-metrics-ingress-sabnzbd.spec = {
          description = "Allow Prometheus to scrape sabnzbd's exportarr sidecar (9707).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "sabnzbd";
          ingress = [
            {
              fromEndpoints = [
                {
                  matchLabels = {
                    "k8s:io.kubernetes.pod.namespace" = "monitoring";
                    "app.kubernetes.io/name" = "prometheus";
                  };
                }
              ];
              toPorts = [ { ports = [ { port = "9707"; protocol = "TCP"; } ]; } ];
            }
          ];
        };

        # NNTP (119) / NNTPS (563) to Usenet providers; 80/443 to indexers / SSL providers.
        allow-internet-egress-sabnzbd.spec = {
          description = "Allow sabnzbd to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "sabnzbd";
          egress = [
            {
              toEntities = [ "world" ];
              toPorts = [
                {
                  ports = [
                    { port = "80"; protocol = "TCP"; }
                    { port = "443"; protocol = "TCP"; }
                    { port = "119"; protocol = "TCP"; }
                    { port = "563"; protocol = "TCP"; }
                  ];
                }
              ];
            }
          ];
        };
      };
    };
}
