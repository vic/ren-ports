{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.smartctl-exporter = sw.distributed (
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
          name = "smartctl-exporter";
          port = 9633;
        })
        serviceName
        servicePort
        ;
    in
    {
      config = {
        swarselsystems.enabledServerModules = [ serviceName ];
        topology.self.services.${serviceName} = {
          icon = "services.prometheus";
          name = serviceName;
        };
        globals = {
          services.${serviceName}.extraConfig.port = servicePort;
        };
        users.persistentIds.smartctl-exporter-access = confLib.mkIds 947;
        services.prometheus.exporters.smartctl = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = servicePort;
        };
        environment.etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
          lib.mkAfter ''
            prometheus.scrape "smartctl" {
              targets         = [{"__address__" = "127.0.0.1:${toString servicePort}"}]
              forward_to      = [prometheus.remote_write.mimir.receiver]
              job_name        = "smartctl"
              scrape_interval = "60s"
            }
          ''
        );
      };
    }

  );
}
