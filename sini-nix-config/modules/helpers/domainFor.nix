# domainFor env service -> public domain of a service: its own domain, else delegated, else under env.domain
# (den schema/environment.nix domainFor).
{ ... }:
let
  svcOf = env: name: env.services.${name} or { };
in
{
  ren.helpers.domainFor =
    env: name:
    if (svcOf env name).domain or null != null then
      (svcOf env name).domain
    else if (svcOf env name).delegateTo or null != null then
      "${name}.${(svcOf env name).delegateTo}.${env.domain}"
    else
      "${name}.${env.domain}";
}
