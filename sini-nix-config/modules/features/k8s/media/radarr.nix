# radarr: Servarr app. Postgres-backed (media-pg, radarr-main + radarr-log dbs), OIDC-protected UI via the
# gateway (AUTH__METHOD=External), fixed API key from the shared media-arr-api-keys secret.
# bjw-s app-template, longhorn config PVC. Sidecars in radarr-logtail.nix / radarr-metrics.nix;
# CNPs in radarr-net.nix; route + OIDC in radarr-route.nix. Image: rolling LSIO `nightly`, digest-pinned
# in images/linuxserver/radarr.
{ ren, ... }:
{
  ren.aspects.k8s-media-radarr = {
    service-domains = [ "radarr" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "radarr" ];

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.radarr = {
          namespace = "media";

          helm.releases.radarr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."linuxserver/radarr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    RADARR__POSTGRES__HOST = "media-pg-rw";
                    RADARR__POSTGRES__PORT = "5432";
                    RADARR__POSTGRES__MAINDB = "radarr-main";
                    RADARR__POSTGRES__LOGDB = "radarr-log";
                    RADARR__POSTGRES__USER.valueFrom.secretKeyRef = {
                      name = "media-pg-radarr-password";
                      key = "username";
                    };
                    RADARR__POSTGRES__PASSWORD.valueFrom.secretKeyRef = {
                      name = "media-pg-radarr-password";
                      key = "password";
                    };
                    # Gateway handles authn; the app trusts it. API key is fixed (shared secret)
                    # so downstream *arrs can register against it.
                    RADARR__AUTH__METHOD = "External";
                    RADARR__AUTH__APIKEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "radarr";
                    };
                    # Bound /config/logs: Servarr rotates at SizeLimit MB/file keeping Rotate
                    # files (SizeLimit clamped 0..10). The file-tail sidecar ships them first.
                    RADARR__LOG__ROTATE = "2";
                    RADARR__LOG__SIZELIMIT = "1";
                  };
                  envFrom = [ ];
                  # Servarr HTTP health endpoint.
                  probes = {
                    liveness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 7878;
                    };
                    readiness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 7878;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 7878;
              };

              persistence.config = {
                type = "persistentVolumeClaim";
                accessMode = "ReadWriteOnce";
                size = "5Gi";
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
