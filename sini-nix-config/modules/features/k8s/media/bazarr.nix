# Bazarr: subtitle manager for Sonarr/Radarr. Postgres-backed via its own POSTGRES_* env (not the
# Servarr __POSTGRES__ convention), single `bazarr` db, creds from media-pg-bazarr-password.
# bjw-s app-template, longhorn config PVC, media-data NFS mount; CNPs/route/OIDC in bazarr-net.nix,
# log-tail sidecar in bazarr-logtail.nix. API key lives in config.ini (no *__AUTH__APIKEY env).
# Image: rolling LSIO `latest`, digest-pinned in images/linuxserver/bazarr.
{ ren, ... }:
{
  ren.aspects.k8s-media-bazarr = {
    service-domains = [ "bazarr" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "bazarr" ];

    age-secrets =
      { environment, ... }:
      {
        age.secrets.bazarr-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/bazarr-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "bazarr";
          };
        };
      };

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.bazarr = {
          namespace = "media";

          helm.releases.bazarr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."linuxserver/bazarr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    POSTGRES_ENABLED = "true";
                    POSTGRES_HOST = "media-pg-rw";
                    POSTGRES_PORT = "5432";
                    POSTGRES_DATABASE = "bazarr";
                    POSTGRES_USERNAME.valueFrom.secretKeyRef = {
                      name = "media-pg-bazarr-password";
                      key = "username";
                    };
                    POSTGRES_PASSWORD.valueFrom.secretKeyRef = {
                      name = "media-pg-bazarr-password";
                      key = "password";
                    };
                  };
                  envFrom = [ ];
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 6767;
              };

              persistence = {
                config = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "2Gi";
                  storageClass = "longhorn";
                  labels."recurring-job-group.longhorn.io/media-config" = "enabled";
                  globalMounts = [ { path = "/config"; } ];
                };
                # Bazarr reads media to write sidecar subtitles; config PVC + /data only, no scratch.
                data = {
                  type = "persistentVolumeClaim";
                  existingClaim = "media-data-nfs";
                  globalMounts = [ { path = "/data"; } ];
                };
              };
            };
          };
        };
      };
  };
}
