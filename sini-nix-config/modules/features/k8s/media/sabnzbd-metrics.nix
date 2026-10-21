# SABnzbd exportarr sidecar (:9707, API over pod loopback; key seeded by config-seed) + PodMonitor.
{ ... }:
{
  ren.aspects.k8s-media-sabnzbd.k8s-manifests =
    { images, ... }:
    {
      applications.sabnzbd = {
        helm.releases.sabnzbd.values.controllers.main.containers.exportarr = {
          image = {
            inherit (images."onedr0p/exportarr") repository digest;
          };
          args = [
            "sabnzbd"
            # Quiet per-scrape HTTP request logging (shipped to loki).
            "--log-level"
            "warn"
          ];
          env = {
            PORT = "9707";
            URL = "http://localhost:8080";
            APIKEY.valueFrom.secretKeyRef = {
              name = "media-arr-api-keys";
              key = "sabnzbd";
            };
          };
          ports = [
            {
              name = "metrics";
              containerPort = 9707;
            }
          ];
        };

        # Raw PodMonitor: no typed accessor without a kube-prometheus-stack CRDs bridge.
        objects = [
          {
            apiVersion = "monitoring.coreos.com/v1";
            kind = "PodMonitor";
            metadata = {
              name = "sabnzbd";
              namespace = "media";
            };
            spec = {
              selector.matchLabels."app.kubernetes.io/name" = "sabnzbd";
              podMetricsEndpoints = [
                {
                  port = "metrics";
                  path = "/metrics";
                  interval = "30s";
                  # Pin instance to the stable app name (pod IP:port churns on restart).
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
      };
    };
}
