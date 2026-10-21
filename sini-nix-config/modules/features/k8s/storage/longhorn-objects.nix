# Longhorn BackupTarget + RecurringJobs + ArgoCD ignoreDifferences. Same aspect as longhorn.nix.
{ ... }:
{
  ren.aspects.k8s-storage-longhorn.k8s-manifests =
    { cluster, ... }:
    let
      # Off-cluster backup target declared on the cluster (type="backup").
      backupNfs = cluster.nfsVolumes."longhorn-backups";
    in
    {
      applications.longhorn = {
        # Off-cluster backups: point the longhorn-created `default` BackupTarget
        # at the NAS NFS export. The chart's longhorn-default-resource ConfigMap
        # only SEEDS a non-existent target, so the existing `default` CR is
        # managed directly here - ArgoCD owns the spec, the longhorn controller
        # owns status (ignored below). NFS needs no credential secret.
        # The longhorn controller (`longhorn-manager` field manager) owns
        # /status and periodically rewrites /spec/syncRequestedAt (+ defaults
        # /spec/credentialSecret), flapping the app OutOfSync every poll. The
        # app uses serverSideDiff, where jsonPointers do NOT suppress this -
        # the SSA-native fix is managedFieldsManagers: ignore everything that
        # field manager owns. argocd-controller still owns (and git enforces)
        # backupTargetURL + pollInterval.
        ignoreDifferences."backup-target" = {
          group = "longhorn.io";
          kind = "BackupTarget";
          name = "default";
          namespace = "longhorn-system";
          managedFieldsManagers = [ "longhorn-manager" ];
        };

        # Longhorn's CRD installer stamps every longhorn.io CRD with
        # chart-version labels (app.kubernetes.io/version, helm.sh/chart,
        # app.kubernetes.io/managed-by) that the crds extraction deliberately
        # strips. The values track the chart version, so they can never match
        # our generated manifests and flap every CRD OutOfSync each poll.
        # Ignore the label paths (jqPathExpressions, not managedFieldsManagers:
        # there is no single owning manager, ownership oscillates).
        ignoreDifferences."crd-chart-labels" = {
          group = "apiextensions.k8s.io";
          kind = "CustomResourceDefinition";
          jqPathExpressions = [
            ''.metadata.labels."app.kubernetes.io/version"''
            ''.metadata.labels."app.kubernetes.io/managed-by"''
            ''.metadata.labels."helm.sh/chart"''
          ];
        };

        objects = [
          {
            apiVersion = "longhorn.io/v1beta2";
            kind = "BackupTarget";
            metadata = {
              name = "default";
              namespace = "longhorn-system";
            };
            spec = {
              backupTargetURL = "nfs://${backupNfs.server}:${backupNfs.share}";
              pollInterval = "5m0s";
            };
          }
        ];
      };
    };
}
