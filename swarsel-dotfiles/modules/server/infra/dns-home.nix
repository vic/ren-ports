{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.dns-home.nixos =
    {
      globals-defs,
      host,
      config,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
      inherit (confLib.static) homeProxy;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ "dns-home" ];
        networking.hosts = {
          ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv4} = [
            "server.${homeProxy}.${globals.domains.main}"
          ];
          ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv6} = [
            "server.${homeProxy}.${globals.domains.main}"
          ];
        };

      };

    }

  ;
}
