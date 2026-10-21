# Certificates only; DNS not managed here (den: certsOnly).
{ ... }:
{
  ren.domain."json64.net" = {
    tls.issuer = "global";
  };
}
