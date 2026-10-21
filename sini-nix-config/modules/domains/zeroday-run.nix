# Certificates only; DNS not managed here (den: certsOnly).
{ ... }:
{
  ren.domain."zeroday.run" = {
    tls.issuer = "global";
  };
}
