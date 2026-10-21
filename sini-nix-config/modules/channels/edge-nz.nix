# channels n-z (edge family): port-forwards; consumer logic = flake/terranix/unifi-*.nix.
# (gateway-policies is declared once, in edge-am.nix.)
{ ren, ... }:
let
  toEnv = e: ren.lib.and [ ren.kinds.environment (ren.lib.when ({ environment, ... }: ren.lib.same environment (e.host or e.cluster).environment)) ];
in
{
  # records { name protocol wanPort forward{ip port} allWans mode }; mode "forward" unless set.
  # No `into`: the unifi-terranix consumer reads the pool (an `into` key would collide with the class output).
  ren.channels.port-forwards = {
    fold = ren.lib.fold.list;
    at = ren.lib.anyOf [ ren.kinds.host ren.kinds.cluster ]; # clusters emit too (envoy-gateway)
    to = toEnv;
  };
}
