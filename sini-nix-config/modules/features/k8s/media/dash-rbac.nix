# Dash RBAC: ServiceAccount "dash" (raw resource so the name is deterministic for the binding subject;
# bound in dash.nix) and a read-only ClusterRole for homepage's kubernetes.yaml mode=cluster discovery.
{ ... }:
{
  ren.aspects.k8s-media-dash.k8s-manifests =
    { ... }:
    {
      applications.dash.resources = {
      serviceAccounts.dash = {
        metadata.namespace = "media";
      };

      clusterRoles."media-dash-discovery" = {
        rules = [
          {
            apiGroups = [ "" ];
            resources = [
              "namespaces"
              "pods"
              "nodes"
              "services"
            ];
            verbs = [
              "get"
              "list"
              "watch"
            ];
          }
          {
            apiGroups = [ "metrics.k8s.io" ];
            resources = [
              "nodes"
              "pods"
            ];
            verbs = [
              "get"
              "list"
            ];
          }
          {
            apiGroups = [ "networking.k8s.io" ];
            resources = [ "ingresses" ];
            verbs = [
              "get"
              "list"
              "watch"
            ];
          }
          {
            apiGroups = [ "gateway.networking.k8s.io" ];
            resources = [ "httproutes" ];
            verbs = [
              "get"
              "list"
              "watch"
            ];
          }
        ];
      };

      clusterRoleBindings."media-dash-discovery" = {
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "media-dash-discovery";
        };
        subjects = [
          {
            kind = "ServiceAccount";
            name = "dash";
            namespace = "media";
          }
        ];
      };
      };
    };
}
