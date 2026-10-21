# a-m channels, k8s: CRDs, cluster -> cluster.
{ ren, ... }:
{
  ren.channels.crds = {
    fold = ren.lib.fold.list;
    at = ren.kinds.cluster;
    to = e: e;
  };
}
