# monitoring-pg - CloudNativePG PostgreSQL cluster backing the monitoring
# stack (grafana today; alerting-era tenants later).
#
# Mirrors the media-pg pattern: 2-instance HA cluster on longhorn-single
# (CNPG owns redundancy via streaming replication), required anti-affinity,
# nightly volumeSnapshot backups. Deliberately separate from media-pg -
# the monitoring stack's state must not share a failure domain with a
# database cluster it monitors.
#
# References the cluster-scoped `longhorn-snapshot` VolumeSnapshotClass
# declared by media-pg.nix. CNPs live in monitoring-pg-policy.nix (same aspect).
{ lib, ... }:
let
  roleApps = [ "grafana" ];
  passwordSecretName = app: "monitoring-pg-${app}-password";
in
{
  ren.aspects.k8s-monitoring-pg = {
    # One generated password per role, rekeyed into the cluster sops store.
    # The .age files are created by `agenix generate` after this lands.
    age-secrets =
      { environment, ... }:
      {
        age.secrets = lib.listToAttrs (
          map (
            app:
            lib.nameValuePair (passwordSecretName app) {
              rekeyFile = environment.secretPath + "/monitoring-pg/${app}-password.age";
              generator.script = "rfc3986-secret";
              sopsOutput = {
                file = "monitoring-pg";
                key = app;
              };
            }
          ) roleApps
        );
      };

    k8s-manifests =
      { config, ... }:
      {
        applications.monitoring-pg = {
          namespace = "monitoring";


          resources = {
            clusters.monitoring-pg.spec = {
              instances = 2;

              storage = {
                size = "5Gi";
                storageClass = "longhorn-single";
              };

              affinity.podAntiAffinityType = "required";

              managed.roles = map (app: {
                name = app;
                login = true;
                passwordSecret.name = passwordSecretName app;
              }) roleApps;

              # Authoritative backup -> off-cluster NAS (type:bak). Local
              # fast-rollback is the db-local-snap Longhorn RecurringJob,
              # enrolled via inheritedMetadata.
              backup.volumeSnapshot.className = "longhorn-backup-nfs";

              inheritedMetadata.labels."recurring-job-group.longhorn.io/db-local-snap" = "enabled";
            };

            databases.grafana.spec = {
              cluster.name = "monitoring-pg";
              name = "grafana";
              owner = "grafana";
            };

            # Nightly backup at 04:00 via longhorn volume snapshot.
            scheduledBackups.monitoring-pg-nightly.spec = {
              schedule = "0 0 4 * * *";
              cluster.name = "monitoring-pg";
              method = "volumeSnapshot";
            };

            secrets = lib.listToAttrs (
              map (
                app:
                lib.nameValuePair (passwordSecretName app) {
                  type = "kubernetes.io/basic-auth";
                  stringData = {
                    username = app;
                    password = config.age.secrets.${passwordSecretName app}.sopsRef;
                  };
                }
              ) roleApps
            );
          };
        };
      };
  };
}
