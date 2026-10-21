# Shoko log-tail sidecar (grafana/alloy): tails Shoko.CLI/logs/*.log (NLog, date-named; old days are
# zipped) off the state PVC. Date filename is the cardinality driver, so it collapses to a static
# `log_file = "shoko"` label. Level from `[<ts>] <Level>|<logger> > <msg>`. Runs as shoko uid 1027 so it
# can read logs and write its offset store at /home/shoko/.shoko/.alloy. NLog self-prunes (not env-tunable).
# CRITICAL: validate any edit with `nix run nixpkgs#grafana-alloy -- fmt`.
{ ... }:
{
  ren.aspects.k8s-media-shoko.k8s-manifests =
    { images, ... }:
    {
      applications.shoko.helm.releases.shoko.values = {
        controllers.main.containers.logtail = {
          image = {
            inherit (images."grafana/alloy") repository digest;
          };
          args = [
            "run"
            "/etc/alloy/config.alloy"
            # tail offsets on the state PVC -> survive pod restart
            "--storage.path=/home/shoko/.shoko/.alloy"
            # keep the alloy UI loopback-only (no CNP needed)
            "--server.http.listen-addr=127.0.0.1:12345"
          ];
          securityContext = {
            runAsUser = 1027;
            runAsGroup = 65536;
          };
        };

        configMaps.logtail.data."config.alloy" = ''
          logging {
            level = "warn"
          }

          local.file_match "logs" {
            path_targets = [{
              "__path__"  = "/home/shoko/.shoko/Shoko.CLI/logs/*.log",
              "app"       = "shoko",
              "namespace" = "media",
            }]
          }

          loki.source.file "logs" {
            targets    = local.file_match.logs.targets
            forward_to = [loki.process.logs.receiver]
          }

          loki.process "logs" {
            stage.regex {
              expression = "\\]\\s(?P<level>Trace|Debug|Info|Warn|Error|Fatal)\\|"
            }

            stage.labels {
              values = {
                level = "",
              }
            }

            // Bound stream cardinality: shoko names each day's log by date, so
            // the raw `filename` label grows daily. Collapse it to a static
            // app-level `log_file` label and drop the raw path.
            stage.static_labels {
              values = {
                log_file = "shoko",
              }
            }

            stage.label_drop {
              values = ["filename"]
            }

            forward_to = [loki.write.default.receiver]
          }

          loki.write "default" {
            endpoint {
              url = "http://loki.monitoring.svc:3100/loki/api/v1/push"
            }
        '';

        # Mount the sidecar config into the logtail container only.
        persistence.logtail = {
          type = "configMap";
          identifier = "logtail";
          advancedMounts.main.logtail = [
            {
              path = "/etc/alloy/config.alloy";
              subPath = "config.alloy";
              readOnly = true;
            }
          ];
        };
      };
    };
}
