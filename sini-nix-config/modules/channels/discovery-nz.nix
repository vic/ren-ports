# channels n-z (discovery family): resolved-users, served-domains, site-domains, service-domains.
{ ren, ... }:
{
  # user -> host (C03 A expose)
  ren.channels.resolved-users = {
    fold = ren.lib.fold.list;
    at = ren.kinds.user;
    to = e: e.machine; # host, guest, mac or droid: users live on any machine (opkssh-darwin reads it on macs)
    into = { ... }: u: { resolved-users = u; };
  };

  # host|cluster -> cluster, environment; consumers filter by environment.
  ren.channels.served-domains = {
    fold = ren.lib.fold.list;
    at = ren.lib.anyOf [ ren.kinds.host ren.kinds.cluster ];
    to = _: ren.lib.anyOf [ ren.kinds.cluster ren.kinds.environment ];
    into = { ... }: d: { served-domains = d; };
  };

  # domain -> cluster
  ren.channels.site-domains = {
    fold = ren.lib.fold.list;
    at = ren.kinds.domain;
    to = _: ren.kinds.cluster;
    into = { ... }: d: { site-domains = d; };
  };

  # VERIFY (layout sec 3): 47 emitters, no consumer found; drop if still dead.
  ren.channels.service-domains = {
    fold = ren.lib.fold.list;
    to = e: e.host or e.cluster; # cluster aspects emit too
    into = { ... }: d: { service-domains = d; };
  };
}
