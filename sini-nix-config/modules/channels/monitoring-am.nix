# a-m channels, monitoring: ingest endpoints, cluster -> host.
{ ren, ... }:
{
  ren.channels.monitoring-ingest = {
    fold = ren.lib.fold.list;
    at = ren.kinds.cluster;
    to = _: ren.kinds.host;
  };
}
