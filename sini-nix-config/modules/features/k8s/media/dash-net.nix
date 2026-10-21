# Dash CNPs: gateway-ingress, internet-egress (80/443: icon CDN), in-namespace API egress to the
# surfaced services, and kube-apiserver egress (kubernetes.yaml mode=cluster discovery).
# DNS is coredns.nix cluster-wide egress grant.
{ ... }:
{
  ren.aspects.k8s-media-dash.k8s-manifests =
    { ... }:
    let
      apiEgress = svc: port: {
        toEndpoints = [ { matchLabels."app.kubernetes.io/name" = svc; } ];
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
      applications.dash.resources.ciliumNetworkPolicies = {
        allow-gateway-ingress-dash.spec = {
          description = "Allow Envoy Gateway proxies to reach dash.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "dash";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "3000";
                      protocol = "TCP";
                    }
                  ];
                }
              ];
            }
          ];
        };

        allow-internet-egress-dash.spec = {
          description = "Allow dash to reach the public internet.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "dash";
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

        allow-api-egress-dash.spec = {
          description = "Allow dash to reach the in-namespace media APIs it surfaces.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "dash";
          egress = [
            (apiEgress "lidarr" 8686)
            (apiEgress "radarr" 7878)
            (apiEgress "sabnzbd" 8080)
            (apiEgress "sonarr" 8989)
            (apiEgress "whisparr" 6969)
          ];
        };

        allow-apiserver-egress-dash.spec = {
          description = "Allow dash to reach the kube-apiserver for cluster resource discovery.";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "dash";
          egress = [
            {
              toEntities = [ "kube-apiserver" ];
              toPorts = [
                {
                  ports = [
                    {
                      port = "6443";
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
