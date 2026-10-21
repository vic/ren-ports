# BGP spoke, marker aspect for hub auto-discovery, includes bgp base.
{ ren, ... }:
{
  ren.aspects.svc-bgp-spoke.includes = with ren.aspects; [ svc-bgp ];
}
