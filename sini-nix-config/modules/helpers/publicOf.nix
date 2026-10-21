# publicOf dns proxied -> { address, proxied } or null when the environment publishes no DNS
# (den schema/environment.nix publicOf). dns = env.dns.
{ ... }:
{
  ren.helpers.publicOf =
    dns: proxied:
    if dns.publicIPv4 == null then
      null
    else
      {
        address = dns.publicIPv4;
        inherit proxied;
      };
}
