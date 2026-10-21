{ ren, ... }:
{
  ren.domain."dev.json64.dev" = {
    # Sub-zone with no dns.cloudflare of its own: records hosted in json64.dev zone.
    zone = ren.domain."json64.dev";
  };
}
