# Included by every aspect that consumes ninfer-endpoints, so the hosts a
# restricted ninfer admits are the hosts that use it.
{ ren, ... }:
{
  ren.aspects.svc-ai-ninfer-client-ninfer-clients.fleet-ninfer-clients =
    { environment, host, ... }:
    {
      hostname = host.name;
      ipv4 = ren.helpers.ipv4Of host;
      network = environment.networks.default.cidr;
    };
}
