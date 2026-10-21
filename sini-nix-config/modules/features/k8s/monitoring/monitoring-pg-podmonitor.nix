# monitoring-pg manual metrics PodMonitor. Same aspect as monitoring-pg.nix.
# Replaces CNPG's deprecated monitoring.enablePodMonitor. Relabels `instance` to
# the stable pod name (monitoring-pg-1/2) instead of the ephemeral pod IP:port.
# Replicates the CNPG auto spec; distinct name avoids a handoff race.
{ ... }:
{
  ren.aspects.k8s-monitoring-pg.k8s-manifests.applications.monitoring-pg.objects = [
  {
    apiVersion = "monitoring.coreos.com/v1";
    kind = "PodMonitor";
    metadata = {
      name = "monitoring-pg-metrics";
      namespace = "monitoring";
    };
    spec = {
      selector.matchLabels = {
        "cnpg.io/cluster" = "monitoring-pg";
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
}
