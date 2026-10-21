# SUPERSEDED by configarr (not included from the cluster; do not re-add: both CronJobs would sync
# sonarr/radarr concurrently). Kept for reference.
# Recyclarr: daily CronJob syncing TRaSH quality definitions into Sonarr/Radarr. API keys come from
# media-arr-api-keys via !env_var. Raw bjw-s app-template cronjob controller; CNPs in recyclarr-net.nix.
# Image: rolling `8` tag, digest-pinned in images/recyclarr/recyclarr.
{ ... }:
{
  ren.aspects.k8s-media-recyclarr.k8s-manifests =
    { charts, images, ... }:
    {
      applications.recyclarr = {
        namespace = "media";

        helm.releases.recyclarr = {
          chart = charts.bjw-s-labs.app-template;
          values = {
            controllers.recyclarr = {
              type = "cronjob";
              cronjob = {
                schedule = "0 0 * * *"; # daily at midnight (cluster TZ via env TZ)
                concurrencyPolicy = "Forbid";
                successfulJobsHistory = 3;
                failedJobsHistory = 3;
              };
              containers.main = {
                image = {
                  inherit (images."recyclarr/recyclarr") repository digest;
                };
                # `sync` applies every configured instance.
                args = [ "sync" ];
                env = {
                  TZ = "America/Los_Angeles";
                  SONARR_API_KEY.valueFrom.secretKeyRef = {
                    name = "media-arr-api-keys";
                    key = "sonarr";
                  };
                  RADARR_API_KEY.valueFrom.secretKeyRef = {
                    name = "media-arr-api-keys";
                    key = "radarr";
                  };
                };
              };
            };

            # Minimal starter config; quality_definition sync is the safe baseline.
            configMaps.config.data."recyclarr.yml" = ''
              sonarr:
                series:
                  base_url: http://sonarr:8989
                  api_key: !env_var SONARR_API_KEY
                  quality_definition:
                    type: series

              radarr:
                movies:
                  base_url: http://radarr:7878
                  api_key: !env_var RADARR_API_KEY
                  quality_definition:
                    type: movie
            '';

            persistence.config = {
              type = "configMap";
              identifier = "config";
              globalMounts = [
                {
                  path = "/config/recyclarr.yml";
                  subPath = "recyclarr.yml";
                  readOnly = true;
                }
              ];
            };
          };
        };
      };
    };
}
