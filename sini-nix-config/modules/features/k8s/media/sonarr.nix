# sonarr: Servarr app. Postgres-backed (media-pg, sonarr-main + sonarr-log dbs), OIDC-protected UI via the
# gateway (AUTH__METHOD=External), fixed API key from the shared media-arr-api-keys secret.
# bjw-s app-template, longhorn config PVC. Sidecars in sonarr-logtail.nix / sonarr-metrics.nix;
# CNPs in sonarr-net.nix; route + OIDC in sonarr-route.nix. Image: rolling LSIO `nightly`, digest-pinned
# in images/linuxserver/sonarr.
{ ren, ... }:
{
  ren.aspects.k8s-media-sonarr = {
    service-domains = [ "sonarr" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "sonarr" ];

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.sonarr = {
          namespace = "media";

          helm.releases.sonarr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."linuxserver/sonarr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    SONARR__POSTGRES__HOST = "media-pg-rw";
                    SONARR__POSTGRES__PORT = "5432";
                    SONARR__POSTGRES__MAINDB = "sonarr-main";
                    SONARR__POSTGRES__LOGDB = "sonarr-log";
                    SONARR__POSTGRES__USER.valueFrom.secretKeyRef = {
                      name = "media-pg-sonarr-password";
                      key = "username";
                    };
                    SONARR__POSTGRES__PASSWORD.valueFrom.secretKeyRef = {
                      name = "media-pg-sonarr-password";
                      key = "password";
                    };
                    # Gateway handles authn; the app trusts it. API key is fixed (shared secret)
                    # so downstream *arrs can register against it.
                    SONARR__AUTH__METHOD = "External";
                    SONARR__AUTH__APIKEY.valueFrom.secretKeyRef = {
                      name = "media-arr-api-keys";
                      key = "sonarr";
                    };
                    # Bound /config/logs: Servarr rotates at SizeLimit MB/file keeping Rotate
                    # files (SizeLimit clamped 0..10). The file-tail sidecar ships them first.
                    SONARR__LOG__ROTATE = "2";
                    SONARR__LOG__SIZELIMIT = "1";
                  };
                  envFrom = [ ];
                  # Servarr HTTP health endpoint.
                  probes = {
                    liveness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 8989;
                    };
                    readiness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/ping";
                      port = 8989;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 8989;
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
