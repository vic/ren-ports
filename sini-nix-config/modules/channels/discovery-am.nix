# a-m channels, discovery: host facts shared host -> host (same env AND cluster per layout sec 3).
{ ren, ... }:
let
  hostList = to: {
    fold = ren.lib.fold.list;
    at = ren.kinds.host;
    inherit to;
  };
  anyHost = _: ren.kinds.host;
in
{
  ren.channels.container-registries = hostList ren.helpers.sameCluster;
  ren.channels.gateway-upstreams = hostList ren.helpers.sameCluster;
  ren.channels.gpu-claims = hostList (e: e);
  ren.channels.idm-users = hostList ren.helpers.sameCluster;
  ren.channels.k3s-nodes = hostList ren.helpers.sameCluster;
  ren.channels.media-scratch-exports = hostList ren.helpers.sameCluster;
  ren.channels.exit-nodes = hostList anyHost;
  ren.channels.host-addrs = hostList anyHost;
}
