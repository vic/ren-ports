# qBittorrent log-tail sidecar (grafana/alloy): tails only the ACTIVE /config/qBittorrent/logs/qbittorrent.log
# (.bak rotations excluded, they drove cardinality). Lines prefix a level letter (N|I|W|C) lifted into `level`.
# Runs as PUID 1027 (log files are 0600). Shares the netns with gluetun; the loki push is permitted by
# FIREWALL_OUTBOUND_SUBNETS (172.21.0.0/16). CRITICAL: validate edits with `nix run nixpkgs#grafana-alloy -- fmt`.
{ ... }:
{
  ren.aspects.k8s-media-qbittorrent.k8s-manifests =
    { images, ... }:
    {
      applications.qbittorrent.helm.releases.qbittorrent.values = {
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
              "__path__"  = "/config/qBittorrent/logs/qbittorrent.log",
              "app"       = "qbittorrent",
              "namespace" = "media",
            }]
          }

          loki.source.file "logs" {
            targets    = local.file_match.logs.targets
            forward_to = [loki.process.logs.receiver]
          }

          loki.process "logs" {
            stage.regex {
              expression = "^\\((?P<level>N|I|W|C)\\)"
            }

            stage.labels {
              values = {
                level = "",
              }
            }

            // Bound stream cardinality: replace the per-file `filename`
            // provenance label (one stream per .bak backup) with a static
            // app-level `log_file` label, then drop the raw path.
            stage.static_labels {
              values = {
                log_file = "qbittorrent",
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
