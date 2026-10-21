# Tdarr Prometheus metrics: homeylab/tdarr-exporter v3 sidecar (scrapes the server over pod loopback,
# re-exports on :9090), raw PodMonitor (no typed accessor without a kube-prometheus-stack CRDs bridge).
{ ... }:
{
  ren.aspects.k8s-media-tdarr.k8s-manifests =
    { images, ... }:
    {
      applications.tdarr = {
        helm.releases.tdarr.values.controllers.main.containers.exportarr = {
          image = {
            inherit (images."homeylab/tdarr-exporter") repository digest;
          };
          env = {
            TDARR_URL = "http://localhost:8265";
            PROMETHEUS_PORT = "9090";
            LOG_LEVEL = "warn";
          };
          ports = [
            {
              name = "metrics";
              containerPort = 9090;
            }
          ];
        };

        objects = [
          {
            apiVersion = "monitoring.coreos.com/v1";
            kind = "PodMonitor";
            metadata = {
              name = "tdarr";
              namespace = "media";
            };
            spec = {
              selector.matchLabels."app.kubernetes.io/name" = "tdarr";
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

        resources.ciliumNetworkPolicies.allow-metrics-ingress-tdarr.spec = {
          description = "Allow Prometheus to scrape tdarr's exporter sidecar (9090).";
          endpointSelector.matchLabels."app.kubernetes.io/name" = "tdarr";
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
                      port = "9090";
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
