# kube-prometheus-stack - Helm chart for in-cluster Prometheus monitoring.
#
# Scopes itself to kubernetes-level signals: apiserver, kubelet/cadvisor,
# coredns, kube-state-metrics, and in-cluster ServiceMonitors/PodMonitors.
# Node-level metrics stay with the host stack (every server already runs
# prometheus-exporter on :9100 - an in-cluster node-exporter would clash
# on the hostPort and duplicate the host stack's ownership).
# Split (same aspect): prometheus-values.nix, prometheus-alertmanager.nix,
# prometheus-routes.nix, prometheus-cnp.nix.
{ ren, lib, ... }:
let
  uis = [
    "prometheus"
    "alertmanager"
  ];
in
{
  ren.aspects.k8s-monitoring-prometheus = {
    # Both UIs behind the gateway's kanidm OIDC (admins only: neither has auth
    # of its own, and a silence can mute any alert). They are also the
    # externalUrls, so notification links (silence, source graph) resolve.
    service-domains = uis;
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster uis;

    k8s-manifests =
      {
        charts,
        cluster,
        prometheus-targets,
        ...
      }:
      let
        # The outside Alertmanager (services.monitoring.alertmanager): it
        # receives only the Watchdog and alerts when that stops arriving.
        outsideAlertmanagers = lib.concatMap (
          t: map (e: "${t.ip}:${toString e.port}") (lib.filter (e: e.job == "alertmanager") t.exporters)
        ) (lib.filter (t: t.environment.name == cluster.environment.name) prometheus-targets);
      in
      {
        applications.kube-prometheus-stack = {
          namespace = "monitoring";


          # The prometheus-operator CRDs blow past the 256KiB annotation
          # limit under client-side apply.
          syncPolicy.syncOptions.serverSideApply = true;

          helm.releases.kube-prometheus-stack = {
            chart = charts.prometheus-community.kube-prometheus-stack;

            values.prometheus.prometheusSpec = {
              externalUrl = "https://${ren.helpers.clusterDomainFor cluster "prometheus"}";
              additionalAlertManagerConfigs = lib.optional (outsideAlertmanagers != [ ]) {
                static_configs = [ { targets = outsideAlertmanagers; } ];
                alert_relabel_configs = [
                  {
                    source_labels = [ "alertname" ];
                    regex = "Watchdog";
                    action = "keep";
                  }
                ];
              };

              retention = "30d";
              retentionSize = "10GB";
              enableRemoteWriteReceiver = true;

              # Expose the admin TSDB API (--web.enable-admin-api):
              # /api/v1/admin/tsdb/delete_series + clean_tombstones, so
              # stale/orphaned series can be force-purged (e.g. churned
              # pod-IP `instance` series) instead of waiting out retention -
              # the prometheus analogue of loki's delete API. Prometheus has
              # no external route; the endpoint is reachable only in-cluster
              # (kubectl port-forward / monitoring ns). These endpoints are
              # DESTRUCTIVE - always scope match[] selectors tightly. See
              # docs/runbooks/monitoring-data-cleanup.md.
              enableAdminAPI = true;

              # Pick up ServiceMonitors/PodMonitors/Probes/Rules from any
              # namespace regardless of release label - CNPG, exportarr,
              # and other app-owned monitors don't carry the chart's
              # release label.
              serviceMonitorSelectorNilUsesHelmValues = false;
              podMonitorSelectorNilUsesHelmValues = false;
              probeSelectorNilUsesHelmValues = false;
              ruleSelectorNilUsesHelmValues = false;

              storageSpec.volumeClaimTemplate.spec = {
                storageClassName = "longhorn";
                accessModes = [ "ReadWriteOnce" ];
                resources.requests.storage = "50Gi";
              };
            };
          };
        };
      };
  };
}
