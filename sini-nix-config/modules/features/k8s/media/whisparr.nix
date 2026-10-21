# whisparr: Servarr app. Postgres-backed (media-pg, whisparr-main + whisparr-log dbs), OIDC-protected UI via the
# gateway (AUTH__METHOD=External), fixed API key from the shared media-arr-api-keys secret.
# bjw-s app-template, longhorn config PVC. Sidecars in whisparr-logtail.nix; no metrics exporter;
# CNPs in whisparr-net.nix; route + OIDC in whisparr-route.nix. Image: hotio `v2` (Whisparr v2, Radarr fork; WHISPARR__ env prefix), digest-pinned
# in images/hotio/whisparr.
{ ren, ... }:
{
  ren.aspects.k8s-media-whisparr = {
    service-domains = [ "whisparr" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "whisparr" ];

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.whisparr = {
          namespace = "media";

          helm.releases.whisparr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."hotio/whisparr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    WHISPARR__POSTGRES__HOST = "media-pg-rw";
                    WHISPARR__POSTGRES__PORT = "5432";
                    WHISPARR__POSTGRES__MAINDB = "whisparr-main";
                    WHISPARR__POSTGRES__LOGDB = "whisparr-log";
                    WHISPARR__POSTGRES__USER.valueFrom.secretKeyRef = {
                      name = "media-pg-whisparr-password";
                      key = "username";
                    };
                    WHISPARR__POSTGRES__PASSWORD.valueFrom.secretKeyRef = {
                      name = "media-pg-whisparr-password";
                      key = "password";
                    };
                    # Gateway handles authn; the app trusts it. API key is fixed (shared secret)
                    # so downstream *arrs can register against it.
                    WHISPARR__AUTH__METHOD = "External";
                    WHISPARR__AUTH__APIKEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "whisparr";
                    };
                    # Bound /config/logs: Servarr rotates at SizeLimit MB/file keeping Rotate
                    # files (SizeLimit clamped 0..10). The file-tail sidecar ships them first.
                    WHISPARR__LOG__ROTATE = "2";
                    WHISPARR__LOG__SIZELIMIT = "1";
                  };
                  envFrom = [ ];
                  # Servarr HTTP health endpoint.
                  probes = {
                    liveness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 6969;
                    };
                    readiness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 6969;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 6969;
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
