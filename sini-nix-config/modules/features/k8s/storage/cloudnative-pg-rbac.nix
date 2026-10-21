# RBAC for the cnpg backup pruner (cloudnative-pg-prune.nix). Same aspect.
{ ... }:
let
  pruner = "cnpg-prune-backups";
in
{
  ren.aspects.k8s-storage-cloudnative-pg.k8s-manifests.applications.cloudnative-pg.resources = {
    serviceAccounts.${pruner} = { };

    clusterRoles.${pruner}.rules = [
      {
        apiGroups = [ "postgresql.cnpg.io" ];
        resources = [ "backups" ];
        verbs = [
          "list"
          "delete"
        ];
      }
      {
        apiGroups = [ "snapshot.storage.k8s.io" ];
        resources = [ "volumesnapshots" ];
        verbs = [
          "list"
          "delete"
        ];
      }
    ];

    clusterRoleBindings.${pruner} = {
      roleRef = {
        apiGroup = "rbac.authorization.k8s.io";
        kind = "ClusterRole";
        name = pruner;
      };
      subjects = [
        {
          kind = "ServiceAccount";
          name = pruner;
          namespace = "cnpg-system";
        }
      ];
    };
  };
}
