# Longhorn RecurringJobs (db-local-snap, media-config-backup, filesystem-trim). Same aspect as longhorn.nix.
{ ... }:
{
  ren.aspects.k8s-storage-longhorn.k8s-manifests.applications.longhorn.objects = [
    # Local fast-rollback snapshots for the CNPG database volumes
    # (Longhorn-native, in-cluster - NOT a backup/upload). DB PVCs join
    # the `db-local-snap` group via inheritedMetadata labels on the CNPG
    # clusters. The authoritative off-cluster copy is the CNPG
    # type:bak ScheduledBackup; this is a cheap COW rollback point.
    {
      apiVersion = "longhorn.io/v1beta2";
      kind = "RecurringJob";
      metadata = {
        name = "db-local-snap";
        namespace = "longhorn-system";
      };
      spec = {
        task = "snapshot";
        cron = "0 */6 * * *";
        retain = 4;
        concurrency = 2;
        groups = [ "db-local-snap" ];
      };
    }
    # Nightly off-cluster backup of the app-config volumes (the media app
    # PVCs enrolled via the media-config group label on their config PVC).
    # loki/prometheus are intentionally unlabeled (observability TSDB is
    # treated as ephemeral), and never join via a default-group job.
    {
      apiVersion = "longhorn.io/v1beta2";
      kind = "RecurringJob";
      metadata = {
        name = "media-config-backup";
        namespace = "longhorn-system";
      };
      spec = {
        task = "backup";
        cron = "0 3 * * *";
        retain = 7;
        concurrency = 2;
        groups = [ "media-config" ];
      };
    }
    # Return freed filesystem blocks to Longhorn. Without it a volume's
    # on-disk size only grows: compaction (prometheus, loki) and WAL
    # churn (postgres) leave volumes far larger than their data. Trim is
    # safe for the ephemeral TSDBs, so this one does cover the default
    # group (every unlabelled volume) alongside the labelled ones.
    {
      apiVersion = "longhorn.io/v1beta2";
      kind = "RecurringJob";
      metadata = {
        name = "filesystem-trim";
        namespace = "longhorn-system";
      };
      spec = {
        task = "filesystem-trim";
        cron = "30 5 * * *";
        retain = 0;
        concurrency = 2;
        groups = [
          "default"
          "db-local-snap"
          "media-config"
        ];
      };
    }
  ];
}
