# Certificates only; DNS not managed here (den: certsOnly).
{ ... }:
{
  ren.domain."sinistar.io" = {
    tls.issuer = "global";
  };
}
