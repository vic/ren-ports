# media-pg CNPG Cluster: 2 instances, longhorn-single storage (CNPG owns redundancy via streaming replication),
# required pod anti-affinity, per-app managed roles, one Database CR per (db, owner), nightly snapshot backups.
{ lib, ... }:
{
  ren.aspects.k8s-media-pg.k8s-manifests =
    { ... }:
    {
      applications.media-pg = {
        namespace = "media";

        resources = {
          clusters.media-pg.spec = {
            instances = 2;

            # Metrics scrape is via the manual PodMonitor (media-pg-monitor.nix); CNPG's deprecated
            # monitoring.enablePodMonitor is intentionally NOT set.

            storage = {
              size = "20Gi";
              storageClass = "longhorn-single";
            };

            affinity.podAntiAffinityType = "required";

            managed.roles = map (app: {
              name = app;
              login = true;
              passwordSecret.name = (import ./_media-pg-lib.nix lib).passwordSecretName app;
            }) (import ./_media-pg-lib.nix lib).roleApps;

            # Authoritative backup -> off-cluster NAS (type:bak). The in-cluster longhorn-snapshot VSC stays
            # declared below for manual CSI snapshots; local fast-rollback is the db-local-snap Longhorn
            # RecurringJob, enrolled via inheritedMetadata.
            backup.volumeSnapshot.className = "longhorn-backup-nfs";

            # Enroll this cluster's PVCs into the db-local-snap RecurringJob group (every 6h, retain 4).
            inheritedMetadata.labels."recurring-job-group.longhorn.io/db-local-snap" = "enabled";
          };

          # One Database CR per (db, owner); owners are the managed roles above.
          databases = lib.mapAttrs (_crName: d: {
            spec = {
              cluster.name = "media-pg";
              name = d.db;
              owner = d.owner;
            };
          }) (import ./_media-pg-lib.nix lib).databases;

          # Nightly backup at 04:00 via longhorn volume snapshot.
          scheduledBackups.media-pg-nightly.spec = {
            schedule = "0 0 4 * * *";
            cluster.name = "media-pg";
            method = "volumeSnapshot";
          };

          # Longhorn VolumeSnapshotClass for CNPG volumeSnapshot backups (`type: snap`: in-cluster snapshot,
          # no external backupstore required).
          volumeSnapshotClasses.longhorn-snapshot = {
            driver = "driver.longhorn.io";
            deletionPolicy = "Delete";
            parameters.type = "snap";
          };
        };
      };
    };
}
