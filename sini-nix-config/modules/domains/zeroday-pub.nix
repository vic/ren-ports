# Certificates only; DNS not managed here (den: certsOnly).
{ ... }:
{
  ren.domain."zeroday.pub" = {
    tls.issuer = "global";
  };
}
