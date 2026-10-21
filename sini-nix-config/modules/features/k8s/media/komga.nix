# Komga: comics / manga / ebook server, OIDC-protected UI behind the default gateway.
# State (embedded H2/SQLite, thumbnails, search index) under /config (2Gi longhorn PVC);
# library on the shared media NFS at /data (Komga points at /data/media/comics in-app).
# No postgres, no internet-egress CNP (Komf companion not deployed). Gateway OIDC only.
# CNP in komga-net.nix, route/OIDC in komga-route.nix, log-tail sidecar in komga-logtail.nix.
# Image: rolling `latest`, digest-pinned in images/gotson/komga. Not an LSIO image: runs as root.
{ ren, ... }:
{
  ren.aspects.k8s-media-komga = {
    service-domains = [ "komga" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "komga" ];

    age-secrets =
      { environment, ... }:
      {
        age.secrets.komga-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/komga-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "komga";
          };
        };
      };

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.komga = {
          namespace = "media";

          helm.releases.komga = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."gotson/komga") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                  };
                  envFrom = [ ];
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 25600;
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
