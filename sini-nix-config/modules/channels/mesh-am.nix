# a-m channels, mesh: BGP peers, host -> host of the same environment.
{ ren, ... }:
{
  ren.channels.bgp-peers = {
    fold = ren.lib.fold.list;
    at = ren.kinds.host;
    to = ren.helpers.sameEnv;
  };
}
