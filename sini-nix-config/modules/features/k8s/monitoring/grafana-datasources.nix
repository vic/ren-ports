# Grafana datasources (Prometheus, Loki, Alertmanager). Same aspect as grafana.nix.
{ ... }:
{
  ren.aspects.k8s-monitoring-grafana.k8s-manifests.applications.grafana.helm.releases.grafana.values.datasources."datasources.yaml" = {
  # The original records were created without explicit uids;
  # provisioning matches BY uid once one is specified and
  # hard-fails on the lookup miss. Deleting by name first makes
  # the pinned-uid recreate idempotent (provisioned datasources
  # carry no state worth keeping).
  deleteDatasources = [
    {
      name = "Prometheus";
      orgId = 1;
    }
    {
      name = "Loki";
      orgId = 1;
    }
  ];
  datasources = [
    {
      name = "Prometheus";
      uid = "prometheus";
      type = "prometheus";
      access = "proxy";
      url = "http://kube-prometheus-stack-prometheus.monitoring:9090";
      isDefault = true;
      jsonData = {
        # min step = the kps scrape interval (the host instance
        # uses 5s to match its own scraper)
        timeInterval = "30s";
        httpMethod = "POST";
      };
    }
    {
      name = "Loki";
      uid = "loki";
      type = "loki";
      access = "proxy";
      url = "http://loki.monitoring:3100";
      jsonData = {
        maxLines = 1000;
      };
    }
    # The cluster Alertmanager, so its alerts and silences
    # (Alerting > Silences, choose this Alertmanager) are
    # manageable from Grafana.
    {
      name = "Alertmanager";
      uid = "alertmanager";
      type = "alertmanager";
      access = "proxy";
      url = "http://kube-prometheus-stack-alertmanager.monitoring:9093";
      jsonData = {
        implementation = "prometheus";
        handleGrafanaManagedAlerts = false;
      };
    }
  ];
  };
}
