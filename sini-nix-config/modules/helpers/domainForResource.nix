# domainForResource cluster service -> gateway listener resource name of the service's domain
# (last two labels, hyphenated: glance.json64.dev -> json64-dev). den schema/cluster.nix.
{ ren, ... }:
{
  ren.helpers.domainForResource =
    cluster: name: ren.helpers.resourceForDomain (ren.helpers.clusterDomainFor cluster name);
}
