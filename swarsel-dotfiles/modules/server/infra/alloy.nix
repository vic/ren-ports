{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.alloy = sw.distributed (
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
          name = "alloy";
          port = 12345;
        })
        serviceName
        servicePort
        ;
      inherit (confLib.static)
        homeWebProxy
        inWgHome
        inWgProxy
        isHome
        webProxy
        ;

      otlpGrpcPort = 4317;
      otlpHttpPort = 4318;

      wgProxyHosts = globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".hosts;
      wgHomeHosts = globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome".hosts;

      mimirDomain = globals.services.mimir.domain;
      lokiDomain = globals.services.loki.domain;
      tempoDomain = globals.services.tempo.domain;
      pyroscopeDomain = globals.services.pyroscope.domain;

      config-alloy = ''
        logging {
          level  = "warn"
          format = "logfmt"
        }
      '';
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        globals = {
          services.${serviceName}.extraConfig = {
            inherit otlpGrpcPort otlpHttpPort;
            clients.${host.name} = true;
            httpPort = servicePort;
          };
          monitoring.hostNetworks.${host.name} = [
            "local-${host.name}"
          ]
          ++ lib.optional isHome "home-lan"
          ++ lib.optional inWgHome "wgHome"
          ++ lib.optional inWgProxy "wgProxy"
          ++ lib.optional (
            globals.hosts.${host.name}.wanAddress4 != null
            || globals.hosts.${host.name}.wanAddress6 != null
          ) "internet"
          ++ lib.mapAttrsToList (vlan: _: "${vlan}-vlan") (
            lib.filterAttrs (_: vlan: vlan ? hosts && vlan.hosts ? "${host.name}") (
              globals.networks.home-lan.vlans or { }
            )
          );
        };
        services.${serviceName} = {
          enable = true;
          extraFlags = [ "--server.http.listen-addr=127.0.0.1:${toString servicePort}" ];
        };
        environment = {
          etc."alloy/config.alloy".text = config-alloy;
          persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
            directories = [
              {
                directory = "/var/lib/private/alloy";
                mode = "0700";
              }
            ];
          };
        };
        networking.hosts =
          let
            proxyIp =
              if isHome && inWgHome then
                wgHomeHosts.${homeWebProxy}.ipv4
              else if inWgProxy then
                wgProxyHosts.${webProxy}.ipv4
              else
                null;
          in
          lib.optionalAttrs (proxyIp != null) {
            ${proxyIp} = [
              mimirDomain
              lokiDomain
              tempoDomain
              pyroscopeDomain
            ];
          };
        systemd.services.alloy.serviceConfig = {
          AmbientCapabilities = [
            "CAP_BPF"
            "CAP_SYS_PTRACE"
            "CAP_NET_RAW"
            "CAP_CHECKPOINT_RESTORE"
            "CAP_DAC_READ_SEARCH"
            "CAP_PERFMON"
            "CAP_SYS_RESOURCE"
            "CAP_SYSLOG"
          ];
          CapabilityBoundingSet = [
            "CAP_BPF"
            "CAP_SYS_PTRACE"
            "CAP_NET_RAW"
            "CAP_CHECKPOINT_RESTORE"
            "CAP_DAC_READ_SEARCH"
            "CAP_PERFMON"
            "CAP_SYS_RESOURCE"
            "CAP_SYSLOG"
          ];
          RestartSec = lib.mkForce "60";
        };

      };
    }

  );
}
