# lidarr: music PVR for the *arr stack. Postgres-backed (media-pg, lidarr-main + lidarr-log dbs), OIDC-protected UI via the
# gateway (AUTH__METHOD=External), fixed API key from the shared media-arr-api-keys secret.
# bjw-s app-template, longhorn config PVC. Sidecars in lidarr-logtail.nix / lidarr-metrics.nix; storage in
# lidarr-storage.nix; CNPs in lidarr-net.nix; route in lidarr-route.nix; OIDC secret in lidarr-oidc.nix.
# Image: rolling LSIO `nightly`, digest-pinned in images/linuxserver/lidarr.
{ ren, ... }:
{
  ren.aspects.k8s-media-lidarr = {
    service-domains = [ "lidarr" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "lidarr" ];

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.lidarr = {
          namespace = "media";

          helm.releases.lidarr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."linuxserver/lidarr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    LIDARR__POSTGRES__HOST = "media-pg-rw";
                    LIDARR__POSTGRES__PORT = "5432";
                    LIDARR__POSTGRES__MAINDB = "lidarr-main";
                    LIDARR__POSTGRES__LOGDB = "lidarr-log";
                    LIDARR__POSTGRES__USER.valueFrom.secretKeyRef = {
                      name = "media-pg-lidarr-password";
                      key = "username";
                    };
                    LIDARR__POSTGRES__PASSWORD.valueFrom.secretKeyRef = {
                      name = "media-pg-lidarr-password";
                      key = "password";
                    };
                    # Gateway handles authn; the app trusts it. API key is fixed (shared secret)
                    # so downstream *arrs can register against it.
                    LIDARR__AUTH__METHOD = "External";
                    LIDARR__AUTH__APIKEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "lidarr";
                    };
                    # Bound /config/logs: Servarr rotates at SizeLimit MB/file keeping Rotate
                    # files (SizeLimit clamped 0..10). The file-tail sidecar ships them first.
                    LIDARR__LOG__ROTATE = "2";
                    LIDARR__LOG__SIZELIMIT = "1";
                  };
                  envFrom = [ ];
                  # Servarr HTTP health endpoint.
                  probes = {
                    liveness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 8686;
                    };
                    readiness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 8686;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 8686;
              };

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
