# Grafana Alloy, every host's push of metrics and logs to the cluster.
# Baseline on every host: systemd journal plus loopback scrape of each exporter the host announces
# via prometheus-targets, pushed with basic auth to the ingest of environment.monitoring.ingest
# (monitoring-ingest channel). No ingest, Alloy is off.
# Labels: metrics job/instance(host name)/cluster(env); logs job=systemd-journal, instance, cluster, unit, level.
{ ... }:
{
  ren.aspects.svc-alloy = {
    nixos =
      {
        environment,
        host,
        lib,
        monitoring-ingest,
        prometheus-targets,
        ...
      }:
      let
        ingest = lib.findFirst (i: i.cluster == environment.monitoring.ingest) null monitoring-ingest;
        endpoint = path: ''
          endpoint {
            url = "${ingest.url}${path}"
            basic_auth {
              username      = "${ingest.username}"
              password_file = sys.env("CREDENTIALS_DIRECTORY") + "/ingest-password"
            }
          }
        '';
        common = ''
          instance = "${host.name}",
          cluster  = "${environment.name}",
        '';
        ownExporters = lib.concatMap (t: t.exporters) (
          lib.filter (t: t.hostname == host.name) prometheus-targets
        );
        scrape = e: ''
          prometheus.scrape "${lib.replaceStrings [ "-" ] [ "_" ] e.job}" {
            job_name   = "${e.job}"
            targets    = [{
              __address__ = "127.0.0.1:${toString e.port}",
              ${common}
            }]
            forward_to = [prometheus.remote_write.ingest.receiver]
          }
        '';
      in
      lib.mkIf (ingest != null) {
        environment.etc."alloy/config.alloy".text = ''
          prometheus.remote_write "ingest" {
            ${endpoint "/api/v1/write"}
          }

          loki.write "ingest" {
            ${endpoint "/loki/api/v1/push"}
          }

          ${lib.concatMapStrings scrape ownExporters}

          loki.relabel "journal" {
            forward_to = []
            rule {
              source_labels = ["__journal__systemd_unit"]
              target_label  = "unit"
            }
            rule {
              source_labels = ["__journal_priority_keyword"]
              target_label  = "level"
            }
          }

          loki.source.journal "journal" {
            relabel_rules = loki.relabel.journal.rules
            labels        = {
              job = "systemd-journal",
              ${common}
            }
            forward_to    = [loki.write.ingest.receiver]
          }
        '';
      };

    # Positions and the remote-write WAL survive restarts and reboots.
    persist.directories = [ "/var/lib/private/alloy-host" ];
  };
}
