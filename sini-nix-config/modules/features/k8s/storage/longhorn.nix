# Longhorn - distributed block storage via longhorn/longhorn Helm chart,
# 2-replica default, Retain policy, OIDC dashboard via Kanidm, HTTPRoute,
# CiliumNetworkPolicy. Split: longhorn-objects.nix, longhorn-routes.nix,
# longhorn-cnp.nix (same aspect).
{ ren, ... }:
{
  ren.aspects.k8s-storage-longhorn = {
    service-domains = [ "longhorn" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "longhorn" ];

    crds =
      { inputs, system, ... }:
      {
        name = "longhorn";
        chart = inputs.nixhelm.chartsDerivations.${system}.longhorn.longhorn;
        namePrefix = "longhorn";
      };

    age-secrets =
      { environment, ... }:
      {
        # Shares its rekeyFile AND generator with the kanidm OAuth2 client's
        # basicSecretFile, so both declarations resolve to the same value.
        age.secrets.longhorn-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/longhorn-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "longhorn";
          };
        };
      };

    k8s-manifests =
      { charts, ... }:
      {
        applications.longhorn = {
          namespace = "longhorn-system";

          syncPolicy = {
            syncOptions = {
              serverSideApply = true;
            };
          };

          compareOptions.serverSideDiff = true;

          helm.releases.longhorn = {
            chart = charts.longhorn.longhorn;
            values = {
              longhorn.preUpgradeChecker.jobEnabled = false;

              # Longhorn-manager metrics ServiceMonitor (grafana.com dashboard
              # 13032 imported in monitoring/grafana.nix charts on these).
              metrics.serviceMonitor.enabled = true;

              preUpgradeChecker.upgradeVersionCheck = false;

              defaultSettings = {
                createDefaultDiskLabeledNodes = true;
                defaultDataPath = "/var/lib/longhorn";
                backupstorePollInterval = 300;
                replicaSoftAntiAffinity = true;
                replicaAutoBalance = "best-effort";
                # Cluster-wide default replica count. The longhorn StorageClass
                # already pins numberOfReplicas=2 (persistence.defaultClassReplicaCount
                # below); this aligns the global default (and the dashboard) so any
                # volume created outside that class also defaults to 2, not 3.
                defaultReplicaCount = 2;
                # A CNPG volumeSnapshot backup (type:bak) is an on-demand backup:
                # once uploaded to the NAS, its local snapshot is only dead weight
                # (db-local-snap keeps the local rollback points). And when backup
                # pruning deletes a NAS backup, drop its snapshot.
                autoCleanupSnapshotAfterOnDemandBackupCompleted = true;
                autoCleanupSnapshotWhenDeleteBackup = true;
              };

              persistence = {
                defaultClass = true;
                defaultClassReplicaCount = 2;
                reclaimPolicy = "Retain";
              };

              longhornUI.replicas = 1;
            };
          };
        };
      };
  };
}
