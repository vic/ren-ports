# Cloudflare zone with its own landing page (den: landing).
{ ... }:
{
  ren.domain."qvr.run" = {
    dns = { provider = "cloudflare"; account = "json64"; };
    tls.issuer = "global";
    web = "landing";
  };
}
