{ ren, inputs, ... }:
let
  sw = ren.helpers;
  # the server part writes globals and nodes (helpers/distributed.nix)
  atuinServer = sw.distributed (
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
          name = "atuin";
          port = 8888;
        })
        proxyAddress4
        proxyAddress6
        serviceAddress
        serviceDomain
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeServiceAddress
        homeWebProxy
        isHome
        nginxAccessRules
        webProxy
        ;
    in
    {
      imports = [
      ];
      config = {
        swarselsystems.enabledServerModules = [ "atuin" ];
        topology.self.services.${serviceName}.info = "https://${serviceDomain}";
        globals = {
          services = confLib.mkServiceGlobal {
            inherit
              homeServiceAddress
              isHome
              proxyAddress4
              proxyAddress6
              serviceAddress
              serviceDomain
              serviceName
              ;
          };
          dns = confLib.mkDnsRecord { inherit proxyAddress4 proxyAddress6 serviceName; };
          monitoring.http = confLib.mkHttpMonitoring {
            inherit serviceName servicePort;
            expectedBodyRegex = ''"version":'';
          };
          networks = confLib.mkDualFirewallRules { tcpPorts = [ servicePort ]; };
        };
        services.${serviceName} = {
          enable = true;
          host = "0.0.0.0";
          # openFirewall = true;
          openRegistration = false;
          port = servicePort;
        };
        nodes = lib.mkMerge [
          {
            ${webProxy}.services.nginx = confLib.genNginx {
              inherit
                serviceAddress
                serviceDomain
                serviceName
                servicePort
                ;
              maxBody = 0;
            };
          }
          {
            ${homeWebProxy}.services.nginx = lib.mkIf isHome (
              confLib.genNginx {
                inherit serviceDomain serviceName servicePort;
                extraConfig = nginxAccessRules;
                maxBody = 0;
                serviceAddress = homeServiceAddress;
              }
            );
          }
        ];

      };
    });
in
{
  ren.aspects = {
    atuin.homeManager =
      {
        globals-defs,
        ...
      }:
      let
        globals = sw.globalsOf globals-defs;
        atuinDomain = globals.services.atuin.domain;
      in
      {
        config = {
          swarselsystems.enabledHomeModules = [ "atuin" ];
          programs.atuin = {
            enable = true;
            enableBashIntegration = true;
            enableZshIntegration = true;
            settings = {
              auto_sync = true;
              sync_address = "https://${atuinDomain}";
              sync_frequency = "5m";
            };
          };
        };
      };
    atuin-server.includes = [ ren.aspects.postgresql ];
    atuin-server.nixos = atuinServer.nixos;
    atuin-server.globals-defs = atuinServer.globals-defs;
    atuin-server.nodes = atuinServer.nodes;
  };
}
