# channels n-z (monitoring family): prometheus-targets (prometheus.nix dup decl folded in).
{ ren, ... }:
{
  # host -> host of same env AND cluster of same env (C02 pipes.nix:11-179).
  ren.channels.prometheus-targets = {
    fold = ren.lib.fold.list;
    at = ren.kinds.host;
    to =
      e:
      ren.lib.anyOf [
        (ren.lib.and [ ren.kinds.host (ren.lib.when ({ host, ... }: ren.lib.same host.environment e.host.environment)) ])
        (ren.lib.and [ ren.kinds.cluster (ren.lib.when ({ cluster, ... }: ren.lib.same cluster.environment e.host.environment)) ])
      ];
    into = { ... }: t: { prometheus-targets = t; };
  };
}
