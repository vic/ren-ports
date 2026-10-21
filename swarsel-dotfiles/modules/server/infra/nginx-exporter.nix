{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.nginx-exporter = sw.distributed (
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
          name = "nginx-exporter";
          port = 9113;
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
        services = {
          nginx.statusPage = true;
          prometheus.exporters.nginx = {
            enable = true;
            listenAddress = "127.0.0.1";
            port = servicePort;
          };
        };
        environment.etc."alloy/config.alloy".text = lib.mkIf config.services.alloy.enable (
          lib.mkAfter ''
            prometheus.scrape "nginx" {
              targets    = [{"__address__" = "127.0.0.1:${toString servicePort}"}]
              forward_to = [prometheus.remote_write.mimir.receiver]
              job_name   = "nginx"
            }
          ''
        );
      };
    }

  );
}
