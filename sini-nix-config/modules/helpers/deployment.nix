# deployment host -> { address, user, tags } (den schema/deployment.nix).
# address: first IPv4, else the tailnet name. user: host.deployment.user (layout sec 1).
# tags: environment, then every active named aspect of the machine, sorted (den: sorted identity paths of config.aspects).
# Aspects come from `ren.lib.result.active` (aspect -> [ scope id ]; README:330, read in an `into`, stratum 3).
{ ren, lib, ... }:
let
  onMachine =
    m: ids:
    lib.any (id: lib.any (k: lib.hasSuffix "/${k}:${m.name}" id) [ "host" "mac" "guest" ]) ids;
in
{
  ren.helpers.deployment = host: {
    address =
      if ren.helpers.ipv4Of host == [ ] then
        "${host.name}.ts.${host.environment.domain}"
      else
        builtins.head (ren.helpers.ipv4Of host);
    user = host.deployment.user;
    tags = [ host.environment.name ] ++ lib.sort (a: b: a < b) (
      lib.attrNames (lib.filterAttrs (_: onMachine host) ren.lib.result.active)
    );
  };
}
