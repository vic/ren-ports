# sameCluster e -> predicate for channel `to`: hosts in the same environment AND the same cluster as emitter e.
# A host with no cluster (clusterOf null) never matches.
{ ren, ... }:
{
  ren.helpers.sameCluster =
    e:
    ren.lib.and [
      (ren.helpers.sameEnv e)
      (ren.lib.when (
        r:
        let
          a = ren.helpers.clusterOf r.host;
          b = ren.helpers.clusterOf e.host;
        in
        a != null && b != null && ren.lib.same a b
      ))
    ];
}
