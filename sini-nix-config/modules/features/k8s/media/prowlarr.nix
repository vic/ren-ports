# prowlarr: Servarr app. Postgres-backed (media-pg, prowlarr-main + prowlarr-log dbs), OIDC-protected UI via the
# gateway (AUTH__METHOD=External), fixed API key from the shared media-arr-api-keys secret.
# bjw-s app-template, longhorn config PVC. Sidecars in prowlarr-logtail.nix / prowlarr-metrics.nix;
# CNPs in prowlarr-net.nix; route + OIDC in prowlarr-route.nix. Image: rolling LSIO `nightly`, digest-pinned
# in images/linuxserver/prowlarr.
{ ren, ... }:
{
  ren.aspects.k8s-media-prowlarr = {
    service-domains = [ "prowlarr" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "prowlarr" ];

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.prowlarr = {
          namespace = "media";

          helm.releases.prowlarr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."linuxserver/prowlarr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    PROWLARR__POSTGRES__HOST = "media-pg-rw";
                    PROWLARR__POSTGRES__PORT = "5432";
                    PROWLARR__POSTGRES__MAINDB = "prowlarr-main";
                    PROWLARR__POSTGRES__LOGDB = "prowlarr-log";
                    PROWLARR__POSTGRES__USER.valueFrom.secretKeyRef = {
                      name = "media-pg-prowlarr-password";
                      key = "username";
                    };
                    PROWLARR__POSTGRES__PASSWORD.valueFrom.secretKeyRef = {
                      name = "media-pg-prowlarr-password";
                      key = "password";
                    };
                    # Gateway handles authn; the app trusts it. API key is fixed (shared secret)
                    # so downstream *arrs can register against it.
                    PROWLARR__AUTH__METHOD = "External";
                    PROWLARR__AUTH__APIKEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "prowlarr";
                    };
                    # Bound /config/logs: Servarr rotates at SizeLimit MB/file keeping Rotate
                    # files (SizeLimit clamped 0..10). The file-tail sidecar ships them first.
                    PROWLARR__LOG__ROTATE = "2";
                    PROWLARR__LOG__SIZELIMIT = "1";
                  };
                  envFrom = [ ];
                  # Servarr HTTP health endpoint.
                  probes = {
                    liveness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 9696;
                    };
                    readiness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 9696;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 9696;
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
