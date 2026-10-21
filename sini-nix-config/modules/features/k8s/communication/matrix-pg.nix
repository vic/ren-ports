# matrix-pg: CloudNativePG PostgreSQL cluster backing the Synapse homeserver.
#
# Its own cluster (the hindsight-pg / coder-pg pattern): 2 instances on
# longhorn-single (CNPG owns redundancy via streaming replication), required
# anti-affinity, nightly volumeSnapshot backups to the NAS.
#
# Synapse refuses to start on a database whose collation is not C, so initdb
# creates it with encoding UTF8 and LC_COLLATE/LC_CTYPE C. The `synapse` role
# owns the database; MAS (mas.nix) gets its own `mas` role and database here.
# Synapse and MAS read credentials from the composed secrets files built in
# synapse-secrets.nix and mas.nix, so there is no DSN secret here.
# References the cluster-scoped `longhorn-snapshot` VolumeSnapshotClass
# declared by media-pg. Policies and PodMonitor in matrix-pg-net.nix.
_:
{
  ren.aspects.k8s-communication-matrix-pg = {
    k8s-manifests =
      { ... }:
      {
        applications.matrix-pg = {
          namespace = "matrix";

          resources = {
            clusters.matrix-pg.spec = {
              instances = 2;
              storage = {
                size = "10Gi";
                storageClass = "longhorn-single";
              };
              affinity.podAntiAffinityType = "required";
              managed.roles = [
                {
                  name = "mas";
                  login = true;
                  passwordSecret.name = "matrix-pg-mas-password";
                }
              ];
              # The app database and its owner role, with the C collation Synapse
              # requires (it checks LC_COLLATE/LC_CTYPE at startup).
              bootstrap.initdb = {
                database = "synapse";
                owner = "synapse";
                secret.name = "matrix-pg-synapse-password";
                encoding = "UTF8";
                localeCollate = "C";
                localeCType = "C";
              };
              # Authoritative backup to the off-cluster NAS (type:bak). Local
              # fast-rollback is the db-local-snap Longhorn RecurringJob,
              # enrolled via inheritedMetadata.
              backup.volumeSnapshot.className = "longhorn-backup-nfs";
              inheritedMetadata.labels."recurring-job-group.longhorn.io/db-local-snap" = "enabled";
            };

            databases.mas.spec = {
              cluster.name = "matrix-pg";
              name = "mas";
              owner = "mas";
            };

            # Nightly 05:00, offset from media-pg/coder-pg (04:00) and
            # hindsight-pg (04:30) so the clusters don't snapshot longhorn at once.
            scheduledBackups.matrix-pg-nightly.spec = {
              schedule = "0 0 5 * * *";
              cluster.name = "matrix-pg";
              method = "volumeSnapshot";
            };
          };
        };
      };
  };
}
