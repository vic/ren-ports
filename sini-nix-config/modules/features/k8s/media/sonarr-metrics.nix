# sonarr Prometheus metrics: exportarr sidecar (scrapes the API over pod loopback, serves :9707),
# raw PodMonitor (no typed accessor without a kube-prometheus-stack CRDs bridge), Prometheus ingress CNP.
{ ... }:
{
  ren.aspects.k8s-media-sonarr.k8s-manifests =
    { images, ... }:
    {
      applications.sonarr = {
        helm.releases.sonarr.values.controllers.main.containers.exportarr = {
          image = {
            inherit (images."onedr0p/exportarr") repository digest;
          };
          args = [
            "sonarr"
            # Quiet per-scrape HTTP request logging (shipped to loki).
            "--log-level"
            "warn"
          ];
          env = {
            PORT = "9707";
            URL = "http://localhost:8989";
            APIKEY.valueFrom.secretKeyRef = {
              name = "media-arr-api-keys";
              key = "sonarr";
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
              name = "sonarr";
              namespace = "media";
            };
            spec = {
              selector.matchLabels."app.kubernetes.io/name" = "sonarr";
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

        resources.ciliumNetworkPolicies.allow-metrics-ingress-sonarr.spec = {
          description = "Allow Prometheus to scrape sonarr's exportarr sidecar (9707).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "sonarr";
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
