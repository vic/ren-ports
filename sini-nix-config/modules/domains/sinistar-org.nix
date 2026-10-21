# Certificates only; DNS not managed here (den: certsOnly).
{ ... }:
{
  ren.domain."sinistar.org" = {
    tls.issuer = "global";
  };
}
