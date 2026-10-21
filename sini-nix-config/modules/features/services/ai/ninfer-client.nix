# Included by every aspect that consumes ninfer-endpoints; pulls in the ninfer-clients emission
# (ninfer-clients.nix) so the hosts a restricted ninfer admits are the hosts that use it.
{ ren, ... }:
{
  ren.aspects.svc-ai-ninfer-client.includes = with ren.aspects; [ svc-ai-ninfer-client-ninfer-clients ];
}
