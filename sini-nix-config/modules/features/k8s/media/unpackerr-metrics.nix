# Unpackerr metrics + network: raw PodMonitor on its own /metrics (5656), Prometheus ingress CNP (its
# only inbound edge, under ingress default-deny), and egress CNP to the four *arr APIs. Inbound
# isolation on the *arrs is owned by the policy matrix.
{ ... }:
{
  ren.aspects.k8s-media-unpackerr.k8s-manifests =
    { ... }:
    let
      # Egress edge to a single *arr service port.
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
      applications.unpackerr = {
        objects = [
          {
            apiVersion = "monitoring.coreos.com/v1";
            kind = "PodMonitor";
            metadata = {
              name = "unpackerr";
              namespace = "media";
            };
            spec = {
              selector.matchLabels."app.kubernetes.io/name" = "unpackerr";
              podMetricsEndpoints = [
                {
                  port = "metrics";
                  path = "/metrics";
                  interval = "30s";
                  # Default instance is the ephemeral pod IP:port, which churns on every
                  # restart; pin it to the stable app name.
                  relabelings = [
                    {
                      sourceLabels = [ "__meta_kubernetes_pod_label_app_kubernetes_io_name" ];
                      targetLabel = "instance";
                    }
                  ];
                }
              ];
            };
          }
        ];

        resources.ciliumNetworkPolicies = {
          allow-metrics-ingress-unpackerr.spec = {
            description = "Allow Prometheus to scrape unpackerr's metrics webserver (5656).";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "unpackerr";
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
                toPorts = [
                  {
                    ports = [
                      {
                        port = "5656";
                        protocol = "TCP";
                      }
                    ];
                  }
                ];
              }
            ];
          };

          allow-arr-egress-unpackerr.spec = {
            description = "Allow unpackerr to reach the *arr APIs (sonarr/radarr/lidarr/whisparr).";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "unpackerr";
            egress = [
              (arrEgress "sonarr" 8989)
              (arrEgress "radarr" 7878)
              (arrEgress "lidarr" 8686)
              (arrEgress "whisparr" 6969)
            ];
          };
        };
      };
    };
}
