# clusterOf host -> the cluster whose `hosts` list contains host, or null.
# A host scope sits under environment, not cluster, so its path binds no `cluster`; read the instances (T topology/access.nix:30).
{ ren, lib, ... }:
{
  ren.helpers.clusterOf =
    h: lib.findFirst (c: lib.any (ren.lib.same h) c.hosts) null (lib.attrValues ren.cluster);
}
