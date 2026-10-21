{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.socks-proxy = sw.distributed (
    {
      globals-defs,
      host,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
      inherit
        (confLib.gen {
          domain = "socks-proxy.${globals.domains.main}";
          name = "socks-proxy";
          port = 1080;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        isHome
        webProxy
        ;

      consumer = "moonside";
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = "services.not-available";
          info = "https://${serviceAddress}";
          name = sw.toCapitalized serviceName;
        };
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceName
              ;
            extra.extraConfig.port = servicePort;
            serviceDomain = "socks-proxy.${globals.domains.main}";
          };
          networks."${webProxy}-wgProxy".hosts.${host.name}.firewallRuleForNode.${consumer}.allowedTCPPorts =
            [
              servicePort
            ];
        };
        users.persistentIds.microsocks = confLib.mkIds 988;
        services.microsocks = {
          enable = true;
          ip = "0.0.0.0";
          port = servicePort;
        };
      };
    });
}
