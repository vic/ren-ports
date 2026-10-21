# Dashboard folder placement for the chart-rendered dashboards. Same aspect as prometheus.nix.
{ lib, ... }:
{
  ren.aspects.k8s-monitoring-prometheus.k8s-manifests.applications.kube-prometheus-stack.objectTransforms =
    lib.mapAttrs'
      (
        dashboard: folder:
        lib.nameValuePair "dashboard-folder-${dashboard}" {
          match = {
            kind = "ConfigMap";
            metadata.name = "kube-prometheus-stack-${dashboard}";
          };
          update.metadata.annotations.grafana_folder = folder;
        }
      )
      {
        k8s-coredns = "Networking";
        alertmanager-overview = "Monitoring";
        prometheus = "Monitoring";
        grafana-overview = "Monitoring";
        nodes = "Hosts";
        node-rsrc-use = "Hosts";
        node-cluster-rsrc-use = "Hosts";
      };
}
