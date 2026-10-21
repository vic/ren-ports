# Hostname: networking.hostName is the host instance name.
{ ren, ... }:
{
  ren.aspects.hostname = {
    at = ren.kinds.host;
    nixos = { host, ... }: { networking.hostName = host.name; };
  };
}
