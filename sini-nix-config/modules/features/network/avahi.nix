{ ... }:
{
  ren.aspects.network-avahi.nixos =
    { host, ... }:
    {
      services.avahi = {
        enable = true;
        allowInterfaces = builtins.attrNames host.networking.interfaces;
        nssmdns4 = true;
        nssmdns6 = true;
        publish = {
          enable = true;
          addresses = true;
          domain = true;
          hinfo = true;
          userServices = true;
          workstation = true;
        };
        openFirewall = true;
      };
    };
}
