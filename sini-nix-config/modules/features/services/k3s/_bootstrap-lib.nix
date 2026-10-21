# Shared bootstrap helpers: shouldInit (single declared cluster member), manifestPath, kubectl/apply cmds.
{ lib, inputs, pkgs, host, k3s-nodes, environment }:
let
  clusterName = host.svc-k3s.clusterName;
  manifestBase = inputs.self + "/generated/manifests/${environment.name}-${clusterName}";
  kubectl = "${lib.getExe pkgs.kubectl} --kubeconfig $KUBECONFIG";
in
{
  inherit kubectl;
  shouldInit = builtins.length (lib.filter (n: n.clusterName == clusterName) k3s-nodes) == 1;
  apply = "${kubectl} apply --server-side --force-conflicts --field-manager=argocd-controller";
  manifestPath =
    name:
    builtins.path {
      path = manifestBase + "/${name}";
      name = "${clusterName}-${builtins.replaceStrings [ "/" "." ] [ "-" "-" ] name}";
    };
}
