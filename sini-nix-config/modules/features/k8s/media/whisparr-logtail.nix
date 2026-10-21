# whisparr log-tail sidecar (grafana/alloy): tails only the ACTIVE /config/logs/whisparr.txt (rotations and
# debug/trace files excluded; Alloy follows the active file across rotation by inode). Servarr line
# format `<ts>|<LEVEL>|<Component>|<msg>`. Static `log_file` label replaces per-file `filename`.
# CRITICAL: validate any edit with `nix run nixpkgs#grafana-alloy -- fmt`.
{ ... }:
{
  ren.aspects.k8s-media-whisparr.k8s-manifests =
    { images, ... }:
    {
      applications.whisparr.helm.releases.whisparr.values = {
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
          # Must read app-written logs (hotio writes as PUID 1027 / PGID 65536).
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
              "__path__"  = "/config/logs/whisparr.txt",
              "app"       = "whisparr",
              "namespace" = "media",
            }]
          }

          loki.source.file "logs" {
            targets    = local.file_match.logs.targets
            forward_to = [loki.process.logs.receiver]
          }

          loki.process "logs" {
            stage.regex {
              expression = "\\|(?P<level>Trace|Debug|Info|Warn|Error|Fatal)\\|"
            }

            stage.labels {
              values = {
                level = "",
              }
            }

            // Bound stream cardinality: replace the per-file `filename`
            // provenance label (one stream per rotated file) with a static
            // app-level `log_file` label, then drop the raw path.
            stage.static_labels {
              values = {
                log_file = "whisparr",
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
