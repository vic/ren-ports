# hindsight-pg: the CNPG Cluster, metrics PodMonitor, nightly backup and Secrets.
{ ... }:
{
  ren.aspects.k8s-ai-hindsight-pg.k8s-manifests =
    { config, ... }:
    {
      applications.hindsight-pg = {
        namespace = "ai";

        # Manual metrics PodMonitor, replacing CNPG's deprecated
        # monitoring.enablePodMonitor. Relabels `instance` to the stable pod
        # name (hindsight-pg-1/2) instead of the ephemeral pod IP:port.
        objects = [
          {
            apiVersion = "monitoring.coreos.com/v1";
            kind = "PodMonitor";
            metadata = {
              name = "hindsight-pg-metrics";
              namespace = "ai";
            };
            spec = {
              selector.matchLabels = {
                "cnpg.io/cluster" = "hindsight-pg";
                "cnpg.io/podRole" = "instance";
              };
              podMetricsEndpoints = [
                {
                  port = "metrics";
                  relabelings = [
                    {
                      sourceLabels = [ "__meta_kubernetes_pod_name" ];
                      targetLabel = "instance";
                    }
                  ];
                }
              ];
            };
          }
        ];

        resources = {
          clusters.hindsight-pg.spec = {
            instances = 2;
            storage = {
              size = "10Gi";
              storageClass = "longhorn-single";
            };

            affinity.podAntiAffinityType = "required";
            # The app database, its owner role, and the extensions hindsight's
            # migrations expect to already exist. postInitApplicationSQL runs
            # as superuser inside the freshly created database, which is the
            # only place CREATE EXTENSION can succeed here.
            bootstrap.initdb = {
              database = "hindsight";
              owner = "hindsight";
              secret.name = "hindsight-pg-hindsight-password";
              postInitApplicationSQL = [
                "CREATE EXTENSION IF NOT EXISTS vector;"
                "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
              ];
            };

            # Authoritative backup → off-cluster NAS (type:bak). Local
            # fast-rollback is the db-local-snap Longhorn RecurringJob,
            # enrolled via inheritedMetadata.
            backup.volumeSnapshot.className = "longhorn-backup-nfs";
            inheritedMetadata.labels."recurring-job-group.longhorn.io/db-local-snap" = "enabled";
          };

          # Nightly backup at 04:30 — offset from the media-pg/coder-pg 04:00
          # window so the three clusters don't snapshot longhorn at once.
          scheduledBackups.hindsight-pg-nightly.spec = {
            schedule = "0 30 4 * * *";
            cluster.name = "hindsight-pg";
            method = "volumeSnapshot";
          };

          # basic-auth secret for the owner role. The nixidy objectTransform
          # rewrites Secret → SopsSecret; the password is a sops ref resolved
          # at render time.
          secrets = {
            hindsight-pg-hindsight-password = {
              type = "kubernetes.io/basic-auth";
              stringData = {
                username = "hindsight";
                password = config.age.secrets.hindsight-pg-hindsight-password.sopsRef;
              };
            };

            hindsight-pg-dsn = {
              type = "Opaque";
              stringData.url = config.age.secrets.hindsight-pg-dsn.sopsRef;
            };
          };
        };
      };
    };
}
