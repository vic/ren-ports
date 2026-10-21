# servedDomains env host spec -> served-domains record for a host serving these services.
# spec: service names, or { services; proxied ? true; } (den schema/environment.nix servedDomains).
# Cluster side: clusterServedDomains.nix.
{ ren, ... }:
let
  norm = spec: if builtins.isList spec then { services = spec; } else spec;
in
{
  ren.helpers.servedDomains = env: host: spec: {
    environment = env.name;
    host = host.name;
    address = ren.helpers.addressOn env "default" host;
    domains = map (ren.helpers.domainFor env) (norm spec).services;
    public = ren.helpers.publicOf env.dns ((norm spec).proxied or true);
  };
}
