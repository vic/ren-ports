# clusterServedDomains cluster spec -> served-domains record for a cluster serving these services.
# spec: service names, or { services; proxied ? true; } (den schema/cluster.nix servedDomains).
{ ren, ... }:
{
  ren.helpers.clusterServedDomains =
    cluster: spec:
    let
      s = if builtins.isList spec then { services = spec; } else spec;
    in
    {
      environment = cluster.environment.name;
      cluster = cluster.name;
      address = cluster.networks.kubernetes-loadbalancers.assignments.default-gateway;
      domains = map (ren.helpers.domainFor cluster.environment) s.services;
      public = ren.helpers.publicOf cluster.environment.dns (s.proxied or true);
    };
}
