# Prometheus — time-series monitoring with static exporter discovery,
# alert rules, 30d retention, nginx proxy, remote-write receiver.
#
# Scrapes every target the environment's hosts announce through the
# prometheus-targets quirk (node exporter, k3s, nginx, headscale, ...).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  serviceDomains = [ "prometheus" ];
in
{
  ren.aspects.svc-monitoring-prometheus = {
    # The ingester announces its own Prometheus like any exporter; it is also
    # how alloy finds where to ship (the host exposing job "prometheus").
    prometheus-targets =
      { environment, host, ... }:
      {
        hostname = host.name;
        ip = builtins.head (ren.helpers.ipv4Of host);
        inherit environment;
        exporters = [
          {
            job = "prometheus";
            port = 9090;
          }
        ];
      };

    nixos =
      {
        prometheus-targets,
        config,
        pkgs,
        environment,
        host,
        lib,
        ...
      }:
      let
        domain = ren.helpers.domainFor environment "prometheus";

        # Collected scrape targets (same-environment scoping guaranteed by
        # collect-prometheus-targets policy)
        envTargets = prometheus-targets;

        allScrapes = lib.flatten (
          map (
            target:
            map (exp: {
              job_name = exp.job;
              target = "${target.ip}:${toString exp.port}";
              labels = {
                inherit (target) hostname;
                exporter = exp.job;
              };
            }) target.exporters
          ) envTargets
        );

        # Group by job_name and merge targets
        targetScrapeConfigs = lib.pipe allScrapes [
          (lib.groupBy (s: s.job_name))
          (lib.mapAttrsToList (
            job_name: entries: {
              inherit job_name;
              static_configs = map (e: {
                targets = [ e.target ];
                inherit (e) labels;
              }) entries;
              metrics_path = "/metrics";
              scrape_interval = if job_name == "node-exporter" then "15s" else "30s";
            }
          ))
        ];
      in
      lib.mkMerge [
        {
          services = {
            prometheus = {
              enable = true;
              port = 9090;
              listenAddress = "0.0.0.0";

              extraFlags = [
                "--web.enable-remote-write-receiver"
                "--enable-feature=remote-write-receiver"
                "--storage.tsdb.retention.time=30d"
                "--storage.tsdb.retention.size=10GB"
                "--web.enable-lifecycle"
              ];

              scrapeConfigs = [
                {
                  job_name = "nginx-exporter";
                  static_configs = [
                    {
                      targets = [ "127.0.0.1:9113" ];
                      labels = {
                        hostname = config.networking.hostName;
                        exporter = "nginx";
                      };
                    }
                  ];
                }
              ]
              ++ targetScrapeConfigs;

              rules = [
                ''
                  groups:
                    - name: node-exporter
                      rules:
                        - alert: HighCPUUsage
                          expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
                          for: 5m
                          labels:
                            severity: warning
                          annotations:
                            summary: "High CPU usage detected"
                            description: "CPU usage is above 80% for more than 5 minutes"

                        - alert: HighMemoryUsage
                          expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
                          for: 5m
                          labels:
                            severity: warning
                          annotations:
                            summary: "High memory usage detected"
                            description: "Memory usage is above 85% for more than 5 minutes"

                        - alert: DiskSpaceLow
                          expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 90
                          for: 5m
                          labels:
                            severity: critical
                          annotations:
                            summary: "Disk space running low"
                            description: "Disk usage is above 90% for more than 5 minutes"
                ''
              ];
            };

            nginx.virtualHosts."${domain}" = {
              forceSSL = true;
              useACMEHost = environment.domain;
              locations."/" = {
                proxyPass = "http://127.0.0.1:9090";
                proxyWebsockets = true;
                extraConfig = ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                '';
              };
            };
          };
        }

        # Fleet rules, delivered by the host's Alertmanager (services.monitoring.alertmanager).
        (lib.mkIf config.services.prometheus.alertmanager.enable {
          services.prometheus = {
            alertmanagers = [ { static_configs = [ { targets = [ "127.0.0.1:9093" ]; } ]; } ];

            # A file of its own: `rules` entries are concatenated into one
            # file, and the YAML rules above would make that two documents.
            ruleFiles = [
              (pkgs.writeText "fleet.rules.json" (
                builtins.toJSON {
                  groups = [
                    {
                      name = "fleet";
                      rules = [
                        {
                          alert = "HostDown";
                          expr = ''up{job="node-exporter"} == 0'';
                          "for" = "5m";
                          labels.severity = "critical";
                          annotations.summary = "{{ $labels.hostname }} node exporter unreachable for 5m";
                        }
                        {
                          alert = "EtcdMemberDown";
                          expr = ''up{job="etcd"} == 0'';
                          "for" = "5m";
                          labels.severity = "critical";
                          annotations.summary = "etcd on {{ $labels.hostname }} unreachable for 5m";
                        }
                      ];
                    }
                  ];
                }
              ))
            ];

          };

        })
      ];

    service-domains = serviceDomains;
    served-domains = { environment, host, ... }: ren.helpers.servedDomains environment host serviceDomains;

    firewall = {
      networking.firewall.allowedTCPPorts = [ 9090 ];
    };

    persist = {
      directories = [
        "/var/lib/prometheus2"
      ];
    };
  };
}
