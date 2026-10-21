# a-m channels, dns: domain emissions -> environment (terranix) or cluster/host.
{ ren, ... }:
let
  atDomain = {
    fold = ren.lib.fold.list;
    at = ren.kinds.domain;
  };
in
{
  ren.channels.apex-domains = atDomain // {
    to = e: ren.lib.upTo ren.kinds.cluster e;
  };
  ren.channels.certificate-domains = atDomain // {
    to = e: ren.lib.upTo ren.kinds.host e;
  };
  ren.channels.dns-records = atDomain // {
    to = e: ren.lib.upTo ren.kinds.environment e;
  };
  ren.channels.dns-zones = atDomain // {
    to = e: ren.lib.upTo ren.kinds.environment e;
  };
}
