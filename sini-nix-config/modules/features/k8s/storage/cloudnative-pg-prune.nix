# Backup retention CNPG lacks for volumeSnapshot backups: a nightly
# prune-backups CronJob keeps the newest `keep` completed backups per
# ScheduledBackup cluster-wide (prune-backups.py). Same aspect as cloudnative-pg.nix;
# RBAC in cloudnative-pg-rbac.nix. keep = 7 matches media-config-backup's retain,
# so databases and app config restore to the same window.
{ ... }:
let
  keep = 7;
  pruner = "cnpg-prune-backups";
in
{
  ren.aspects.k8s-storage-cloudnative-pg.k8s-manifests =
    { images, ... }:
    {
      applications.cloudnative-pg.resources = {
        configMaps."${pruner}-script".data."prune-backups.py" = builtins.readFile ./prune-backups.py;

        # After the 04:00 ScheduledBackups have finished.
        cronJobs.${pruner}.spec = {
          schedule = "0 6 * * *";
          concurrencyPolicy = "Forbid";
          successfulJobsHistoryLimit = 1;
          failedJobsHistoryLimit = 3;
          jobTemplate.spec = {
            backoffLimit = 2;
            template = {
              metadata.labels."app.kubernetes.io/name" = pruner;
              spec = {
                serviceAccountName = pruner;
                restartPolicy = "OnFailure";
                securityContext = {
                  runAsNonRoot = true;
                  runAsUser = 65534;
                  runAsGroup = 65534;
                };
                containers = [
                  {
                    name = pruner;
                    image = "${images."library/python".repository}@${images."library/python".digest}";
                    command = [
                      "python3"
                      "/script/prune-backups.py"
                    ];
                    env = [
                      {
                        name = "KEEP";
                        value = toString keep;
                      }
                    ];
                    volumeMounts = [
                      {
                        name = "script";
                        mountPath = "/script";
                        readOnly = true;
                      }
                    ];
                  }
                ];
                volumes = [
                  {
                    name = "script";
                    configMap.name = "${pruner}-script";
                  }
                ];
              };
            };
          };
        };
      };
    };
}
