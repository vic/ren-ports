# a-m channels, edge: firewall rules (host) and gateway policies (-> environment, unifi-terranix).
{ ren, ... }:
{
  ren.channels.firewall = {
    fold = ren.lib.fold.list;
    to = e: ren.lib.upTo ren.kinds.host e;
    into = { lib, ... }: rules: { nixos = lib.mkMerge rules; };
  };

  ren.channels.gateway-policies = {
    fold = ren.lib.fold.list;
    at = ren.kinds.host;
    to = e: ren.lib.upTo ren.kinds.environment e;
  };
}
