{ ren, ... }:
{
  ren.domain."s3.json64.dev" = {
    # Distinct stem: last-two-labels default (json64-dev) would collide with
    # the json64.dev wildcard (the *.s3.json64.dev listener and cert).
    tls = { issuer = "json64-dev"; resourceName = "s3-json64-dev"; };
    # S3 vhost-style buckets: grey, proxied 100 MB cap breaks multipart. Hosted in json64.dev zone.
    zone = ren.domain."json64.dev";
    records = [ { name = "*"; type = "A"; } ];
  };
}
