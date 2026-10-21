# agenix battery, cluster side: the age-secrets channel (channels/secrets-am.nix) imports each emitted
# module straight into the cluster's k8s-manifests class, so there is no bridge to write here.
{ ren, ... }:
{
  ren.aspects.secrets-agenix-cluster.at = ren.kinds.cluster;
}
