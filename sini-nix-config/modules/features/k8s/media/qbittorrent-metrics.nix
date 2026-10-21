# qBittorrent metrics: esanchezm exporter sidecar (WebUI over pod loopback, no credentials since
# LocalHostAuth is off; :9710 avoids gluetun's :8000), raw PodMonitor, Prometheus ingress CNP.
# Reachable only because gluetun's FIREWALL_INPUT_PORTS accepts 9710 on eth0 (second, independent gate).
{ ... }:
{
  ren.aspects.k8s-media-qbittorrent.k8s-manifests =
    { images, ... }:
    {
      applications.qbittorrent = {
        helm.releases.qbittorrent.values.controllers.main.containers.exportarr = {
          image = {
            inherit (images."esanchezm/prometheus-qbittorrent-exporter") repository digest;
          };
          env = {
            QBITTORRENT_HOST = "localhost";
            QBITTORRENT_PORT = "8080";
            QBITTORRENT_USER = "";
            QBITTORRENT_PASS = "";
            EXPORTER_PORT = "9710";
            # Quiet the per-scrape retry/connection chatter (shipped to loki).
            EXPORTER_LOG_LEVEL = "WARNING";
          };
          ports = [
            {
              name = "metrics";
              containerPort = 9710;
            }
          ];
        };

        objects = [
          {
            apiVersion = "monitoring.coreos.com/v1";
            kind = "PodMonitor";
            metadata = {
              name = "qbittorrent";
              namespace = "media";
            };
            spec = {
              selector.matchLabels."app.kubernetes.io/name" = "qbittorrent";
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

        resources.ciliumNetworkPolicies.allow-metrics-ingress-qbittorrent.spec = {
          description = "Allow Prometheus to scrape qbittorrent's exporter sidecar (9710).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "qbittorrent";
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
                      port = "9710";
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
