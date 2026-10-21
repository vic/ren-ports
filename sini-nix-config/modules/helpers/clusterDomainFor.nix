# clusterDomainFor cluster service -> public domain of a service in the cluster's environment
# (den schema/cluster.nix methods.domainFor; cluster.environment is a ref -> instance record).
{ ren, ... }:
{
  ren.helpers.clusterDomainFor = cluster: ren.helpers.domainFor cluster.environment;
}
