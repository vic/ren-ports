# Bazarr log-tail sidecar (grafana/alloy): tails only the ACTIVE /config/log/bazarr.log (date-suffixed
# rotations excluded; they drove cardinality). Pipe-delimited `<ts>|<LEVEL>|<component>|<msg>` format.
# Static `log_file` label replaces per-file `filename`. Bazarr has no metrics exporter.
# CRITICAL: validate any edit with `nix run nixpkgs#grafana-alloy -- fmt`.
{ ... }:
{
  ren.aspects.k8s-media-bazarr.k8s-manifests =
    { images, ... }:
    {
      applications.bazarr.helm.releases.bazarr.values = {
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
          # Must read app-written logs (LSIO writes as PUID 1027 / PGID 65536).
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
              "__path__"  = "/config/log/bazarr.log",
              "app"       = "bazarr",
              "namespace" = "media",
            }]
          }

          loki.source.file "logs" {
            targets    = local.file_match.logs.targets
            forward_to = [loki.process.logs.receiver]
          }

          loki.process "logs" {
            stage.regex {
              // Bazarr emits the level in upper case (INFO|WARNING|...) padded
              // with spaces before the pipe; match case-insensitively.
              expression = "(?i)\\|(?P<level>trace|debug|info|warn|warning|error|fatal|critical)\\s*\\|"
            }

            stage.labels {
              values = {
                level = "",
              }
            }

            // Bound stream cardinality: replace the per-file `filename`
            // provenance label (one stream per dated rotation) with a static
            // app-level `log_file` label, then drop the raw path.
            stage.static_labels {
              values = {
                log_file = "bazarr",
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
