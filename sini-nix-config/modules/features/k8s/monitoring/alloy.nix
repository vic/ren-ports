# Alloy - Grafana Alloy shipping cluster logs to loki.
#
# Two releases of the same chart:
#   - alloy: DaemonSet tailing CRI logs from /var/log/pods on every node
#     (filtered to the local node via the kubernetes API); see alloy-daemonset.nix.
#   - alloy-events: single-replica Deployment turning kubernetes events
#     into loki streams. Deliberately NOT part of the DaemonSet - the
#     kubernetes_events source is not replica-aware and a DS would ship
#     every event once per node.
{ ... }:
{
  ren.aspects.k8s-monitoring-alloy.k8s-manifests =
    { charts, ... }:
    {
      applications.alloy = {
        namespace = "monitoring";

        helm.releases.alloy-events = {
          chart = charts.grafana.alloy;

          values = {
            serviceMonitor.enabled = true;

            controller = {
              type = "deployment";
              replicas = 1;
            };

            alloy.configMap.content = ''
              loki.source.kubernetes_events "cluster_events" {
                forward_to = [loki.write.loki.receiver]
              }

              loki.write "loki" {
                endpoint {
                  url = "http://loki.monitoring.svc:3100/loki/api/v1/push"
                }
              }
            '';
          };
        };

        # Pod discovery (node-local filter) and the events watch talk to
        # the kube-apiserver; the loki push stays inside the cluster
        # (allow-internal-egress). The name label covers both releases.
        resources.ciliumNetworkPolicies.allow-alloy-kube-apiserver-egress.spec = {
          endpointSelector.matchLabels."app.kubernetes.io/name" = "alloy";
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
