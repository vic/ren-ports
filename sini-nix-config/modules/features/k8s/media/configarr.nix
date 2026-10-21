# Configarr: syncs TRaSH-Guides quality definitions / profiles into sonarr/radarr (+ experimental
# lidarr/whisparr) on a daily CronJob; no UI, Service or route. Successor to recyclarr; consumes
# Recyclarr config-templates. API keys via the `!env` YAML tag from the shared media-arr-api-keys
# secret (no secrets.yml). Repo cache is an ephemeral emptyDir (each run re-clones; no PVC).
# config.yml ConfigMap in configarr-config.nix, CNPs in configarr-net.nix. Ingress lockdown lives in
# network-policy.nix. Image: rolling `latest`, digest-pinned in images/raydak-labs/configarr.
{ ... }:
{
  ren.aspects.k8s-media-configarr = {
    k8s-manifests =
      { charts, images, ... }:
      let
        schedule = "0 0 * * *"; # daily at midnight (cluster TZ via env TZ)
      in
      {
        applications.configarr = {
          namespace = "media";

          helm.releases.configarr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              # configarr's `git` is linked against c-ares (libcurl→libcares),
              # not musl getaddrinfo. Under the cluster default ndots:5,
              # `github.com` (1 dot < 5) is resolved search-domains-first, and
              # c-ares stalls on the cluster.local permutations where musl does
              # not — so the TRaSH/recyclarr clones time out ("Could not resolve
              # host"). ndots:1 makes single-dot names (github.com) resolve as
              # absolute; 0-dot service names (sonarr/radarr/…) still use the
              # search list, so in-cluster lookups are unaffected.
              defaultPodOptions.dnsConfig.options = [
                {
                  name = "ndots";
                  value = "1";
                }
              ];

              controllers.configarr = {
                type = "cronjob";
                cronjob = {
                  inherit schedule;
                  concurrencyPolicy = "Forbid";
                  successfulJobsHistory = 3;
                  failedJobsHistory = 3;
                };
                containers.main = {
                  image = {
                    inherit (images."raydak-labs/configarr") repository digest;
                  };
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
                    LIDARR_API_KEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "lidarr";
                    };
                    WHISPARR_API_KEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "whisparr";
                    };
                  };
                };
              };


              persistence = {
                config = {
                  type = "configMap";
                  identifier = "config";
                  globalMounts = [
                    {
                      path = "/app/config/config.yml";
                      subPath = "config.yml";
                      readOnly = true;
                    }
                  ];
                };

                # Ephemeral repo cache: configarr re-clones the TRaSH +
                # recyclarr-config repos here on each run. emptyDir is fine for
                # a once-daily CronJob (no cross-run persistence needed).
                repos = {
                  type = "emptyDir";
                  globalMounts = [ { path = "/app/repos"; } ];
                };
              };
            };
          };

        };
      };
  };
}
