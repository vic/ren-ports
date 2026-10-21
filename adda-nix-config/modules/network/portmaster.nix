# network: Portmaster application firewall
{ ren, ... }:
{
  ren.aspects.security-portmaster.os = {
    services.portmaster = {
      enable = true;
    };
  };
}
