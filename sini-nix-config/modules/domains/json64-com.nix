# Certificates only; DNS not managed here (den: certsOnly).
{ ... }:
{
  ren.domain."json64.com" = {
    tls.issuer = "global";
  };
}
