# sameEnv e -> predicate for channel `to`: hosts in the same environment as emitter scope e (R:252, R:289).
# `and` stops at the first false, so the kind test guards `r.host` (R:285).
{ ren, ... }:
{
  ren.helpers.sameEnv =
    e:
    ren.lib.and [
      ren.kinds.host
      (ren.lib.when (r: ren.lib.same r.environment e.environment))
    ];
}
