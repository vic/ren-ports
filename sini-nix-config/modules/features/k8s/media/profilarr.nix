# Profilarr: Sonarr/Radarr quality-profile + custom-format sync tool (Dictionarry database). Long-running web app
# owning its state in SQLite on a longhorn /config PVC (media-config recurring-job group); not a CronJob.
# No postgres, media mounts, metrics or logtail sidecars. AUTH=off: the gateway OIDC (profilarr-route.nix) is the
# sole gate. Arr connections (sonarr/radarr only) are entered in the UI post-deploy (upstream #401).
# ndots:1: its git clone of github.com stalls under the cluster default ndots:5. CNPs in profilarr-net.nix.
# Image: ghcr `develop` (only v2 channel), digest-pinned in images/dictionarry-hub/profilarr.
{ ren, ... }:
{
  ren.aspects.k8s-media-profilarr = {
    service-domains = [ "profilarr" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "profilarr" ];

    k8s-manifests =
      { cluster, charts, images, ... }:
      {
        applications.profilarr = {
          namespace = "media";

          helm.releases.profilarr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              defaultPodOptions.dnsConfig.options = [
                {
                  name = "ndots";
                  value = "1";
                }
              ];

              controllers.main = {
                type = "deployment";

                containers.main = {
                  image = {
                    inherit (images."dictionarry-hub/profilarr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    # Gateway OIDC is the sole gate (Servarr External model).
                    AUTH = "off";
                    # External origin for CSRF / reverse-proxy correctness.
                    ORIGIN = "https://${ren.helpers.clusterDomainFor cluster "profilarr"}";
                  };
                  # Profilarr has no documented HTTP health path; TCP/6868.
                  probes = {
                    liveness = {
                      enabled = true;
                      type = "TCP";
                      port = 6868;
                    };
                    readiness = {
                      enabled = true;
                      type = "TCP";
                      port = 6868;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 6868;
              };

              # SQLite DB + cloned git repos. longhorn RWO; media-config label enrolls it in the NAS backup group.
              persistence.config = {
                type = "persistentVolumeClaim";
                accessMode = "ReadWriteOnce";
                size = "2Gi";
                storageClass = "longhorn";
                labels."recurring-job-group.longhorn.io/media-config" = "enabled";
                globalMounts = [ { path = "/config"; } ];
              };
            };
          };
        };
      };
  };
}
