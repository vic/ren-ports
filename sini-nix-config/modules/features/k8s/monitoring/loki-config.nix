# Loki server config (single-binary, filesystem tsdb, 30d retention). Same aspect as loki.nix.
{ ... }:
{
  ren.aspects.k8s-monitoring-loki.k8s-manifests.applications.loki.helm.releases.loki.values.loki = {
  auth_enabled = false;

  commonConfig.replication_factor = 1;

  storage = {
    type = "filesystem";
  };

  schemaConfig.configs = [
    {
      from = "2026-06-01";
      store = "tsdb";
      object_store = "filesystem";
      schema = "v13";
      index = {
        prefix = "index_";
        period = "24h";
      };
    }
  ];

  limits_config = {
    retention_period = "30d";
  };

  compactor = {
    retention_enabled = true;
    retention_delete_delay = "2h";
    delete_request_store = "filesystem";
  };
};
}
