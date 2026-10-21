# Komga log-tail sidecar (grafana/alloy): tails only the ACTIVE /config/logs/komga.log (rotated
# history is gzipped `*.log.<date>.N.gz`, not tailed; komga's default logback rotation is kept).
# Logback line: `<ts>  <LEVEL> <pid> --- [...] : <msg>`. Static `log_file` label replaces `filename`.
# Runs as root: the gotson/komga image ignores PUID/PGID and writes logs + /config as uid 0.
# CRITICAL: validate any edit with `nix run nixpkgs#grafana-alloy -- fmt`.
{ ... }:
{
  ren.aspects.k8s-media-komga.k8s-manifests =
    { images, ... }:
    {
      applications.komga.helm.releases.komga.values = {
        controllers.main.containers.logtail = {
          image = {
            inherit (images."grafana/alloy") repository digest;
          };
          args = [
            "run"
            "/etc/alloy/config.alloy"
            # tail offsets on the config PVC -> survive pod restart
            "--storage.path=/config/.alloy"
            # keep the alloy UI loopback-only (no CNP needed)
            "--server.http.listen-addr=127.0.0.1:12345"
          ];
          securityContext = {
            runAsUser = 0;
            runAsGroup = 0;
          };
        };

        configMaps.logtail.data."config.alloy" = ''
          logging {
            level = "warn"
          }

          local.file_match "logs" {
            path_targets = [{
              "__path__"  = "/config/logs/komga.log",
              "app"       = "komga",
              "namespace" = "media",
            }]
          }

          loki.source.file "logs" {
            targets    = local.file_match.logs.targets
            forward_to = [loki.process.logs.receiver]
          }

          loki.process "logs" {
            stage.regex {
              expression = "\\s(?P<level>TRACE|DEBUG|INFO|WARN|ERROR|FATAL)\\s"
            }

            stage.labels {
              values = {
                level = "",
              }
            }

            // Bound stream cardinality: replace the raw per-file `filename`
            // provenance label with a static app-level `log_file` label, then
            // drop the raw path.
            stage.static_labels {
              values = {
                log_file = "komga",
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
