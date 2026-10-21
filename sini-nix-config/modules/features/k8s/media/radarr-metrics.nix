# radarr Prometheus metrics: exportarr sidecar (scrapes the API over pod loopback, serves :9707),
# raw PodMonitor (no typed accessor without a kube-prometheus-stack CRDs bridge), Prometheus ingress CNP.
{ ... }:
{
  ren.aspects.k8s-media-radarr.k8s-manifests =
    { images, ... }:
    {
      applications.radarr = {
        helm.releases.radarr.values.controllers.main.containers.exportarr = {
          image = {
            inherit (images."onedr0p/exportarr") repository digest;
          };
          args = [
            "radarr"
            # Quiet per-scrape HTTP request logging (shipped to loki).
            "--log-level"
            "warn"
          ];
          env = {
            PORT = "9707";
            URL = "http://localhost:7878";
            APIKEY.valueFrom.secretKeyRef = {
              name = "media-arr-api-keys";
              key = "radarr";
            };
          };
          ports = [
            {
              name = "metrics";
              containerPort = 9707;
            }
          ];
        };

        objects = [
          {
            apiVersion = "monitoring.coreos.com/v1";
            kind = "PodMonitor";
            metadata = {
              name = "radarr";
              namespace = "media";
            };
            spec = {
              selector.matchLabels."app.kubernetes.io/name" = "radarr";
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

        resources.ciliumNetworkPolicies.allow-metrics-ingress-radarr.spec = {
          description = "Allow Prometheus to scrape radarr's exportarr sidecar (9707).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "radarr";
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
                      port = "9707";
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
