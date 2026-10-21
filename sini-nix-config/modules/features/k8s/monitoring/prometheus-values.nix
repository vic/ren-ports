# kube-prometheus-stack chart values: host rules, bundled-component toggles.
# Same aspect as prometheus.nix.
{ lib, ... }:
{
  ren.aspects.k8s-monitoring-prometheus.k8s-manifests =
    { cluster, prometheus-targets, ... }:
    let
      # Hosts that push here (their environment's monitoring.ingest names
      # this cluster) and run a node exporter: the set HostSilent expects.
      expectedHosts = lib.unique (
        map (t: t.hostname) (
          lib.filter (
            t:
            (t.environment.monitoring.ingest or null) == cluster.name
            && lib.any (e: e.job == "node-exporter") t.exporters
          ) prometheus-targets
        )
      );
      nodeUp = instance: ''up{job="node-exporter", instance="${instance}"}'';
    in
    {
      applications.kube-prometheus-stack.helm.releases.kube-prometheus-stack.values = {
        # The bundled grafana stays off (grafana.nix owns the instance),
        # but its standard dashboard ConfigMaps still render for the
        # sidecar there to pick up.
        # Host monitoring (hosts push through ingest.nix).
        # The node-exporter mixin's alerts already select job
        # node-exporter; its Linux dashboards go to Hosts.
        nodeExporter = {
          forceDeployDashboards = true;
          operatingSystems = {
            aix.enabled = false;
            darwin.enabled = false;
          };
        };

        additionalPrometheusRulesMap.hosts.groups = [
          {
            name = "hosts";
            rules =
              map (instance: {
                alert = "HostSilent";
                expr = "absent_over_time(${nodeUp instance}[5m]) or max_over_time(${nodeUp instance}[5m]) < 1";
                "for" = "5m";
                labels = {
                  severity = "critical";
                  inherit instance;
                };
                annotations.summary = "${instance} has sent no node metrics for 10m";
              }) expectedHosts
              ++ [
                {
                  alert = "IngestDown";
                  expr = ''absent_over_time(up{job="node-exporter"}[5m])'';
                  "for" = "5m";
                  labels.severity = "critical";
                  annotations.summary = "No host has pushed node metrics for 10m: the ingest path is down";
                }
              ];
          }
        ];

        grafana = {
          enabled = false;
          forceDeployDashboards = true;
          sidecar.dashboards.annotations.grafana_folder = "Kubernetes";
        };

        # Admission webhook certs via cert-manager instead of the
        # certgen hook jobs: PreSync hooks run before any of the app's
        # resources (including its network policies) are applied, so
        # the job can never reach the apiserver under the cluster's
        # default-deny egress.
        prometheusOperator.admissionWebhooks.certManager.enabled = true;

        # Node metrics are host-stack-owned (see header).
        nodeExporter.enabled = false;
        kubeStateMetrics.enabled = true;

        # k3s embeds the control-plane components in the k3s process;
        # there are no separate endpoints for these to scrape.
        kubeControllerManager.enabled = false;
        kubeScheduler.enabled = false;
        kubeProxy.enabled = false;
        kubeEtcd.enabled = false;

        # The chart's coredns Service selects k8s-app=kube-dns; our
        # coredns chart labels its pods k8s-app=coredns, so the default
        # selector matches nothing and the coredns dashboards read empty.
        coreDns.service.selector."k8s-app" = "coredns";
      };
    };
}
