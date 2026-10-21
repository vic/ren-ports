# media-pg PodMonitor + apiserver egress CNP. Manual PodMonitor replaces CNPG's deprecated
# monitoring.enablePodMonitor: relabels `instance` to the stable pod name (media-pg-1/2) instead of the
# ephemeral pod IP:port. Distinct name avoids an ownership race with the auto PodMonitor. Replicates the CNPG
# auto spec (selector cnpg.io/cluster + podRole=instance, port `metrics`/9187); the prometheus->9187 allow in
# network-policy.nix covers it.
{ ... }:
{
  ren.aspects.k8s-media-pg.k8s-manifests =
    { ... }:
    {
      applications.media-pg = {
        objects = [
          {
            apiVersion = "monitoring.coreos.com/v1";
            kind = "PodMonitor";
            metadata = {
              name = "media-pg-metrics";
              namespace = "media";
            };
            spec = {
              selector.matchLabels = {
                "cnpg.io/cluster" = "media-pg";
                "cnpg.io/podRole" = "instance";
              };
              podMetricsEndpoints = [
                {
                  port = "metrics";
                  relabelings = [
                    {
                      sourceLabels = [ "__meta_kubernetes_pod_name" ];
                      targetLabel = "instance";
                    }
                  ];
                }
              ];
            };
          }
        ];

        # CNPG instance pods (instance manager) talk to the kube-apiserver.
        resources.ciliumNetworkPolicies.allow-media-pg-apiserver-egress = {
          metadata.annotations."argocd.argoproj.io/sync-wave" = "-1";
          spec = {
            description = "Allow media-pg CNPG instance pods to talk to kube-apiserver.";
            endpointSelector.matchLabels."cnpg.io/cluster" = "media-pg";
            egress = [
              {
                toEntities = [ "kube-apiserver" ];
                toPorts = [
                  {
                    ports = [
                      {
                        port = "443";
                        protocol = "TCP";
                      }
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
    };
}
