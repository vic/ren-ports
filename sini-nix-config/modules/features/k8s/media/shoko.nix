# Shoko: AniDB-backed anime cataloging server (sonarr acquires, shoko catalogs). Official image (not
# LSIO): state lives at /home/shoko/.shoko, PUID/PGID honored; shared media data PVC at /data for
# import folders. LuaRenamer plugin install in shoko-plugin.nix, log-tail in shoko-logtail.nix,
# CNPs in shoko-net.nix, route/OIDC in shoko-route.nix.
# Image: rolling `latest`, digest-pinned in images/shokoanime/server.
{ ren, ... }:
{
  ren.aspects.k8s-media-shoko = {
    service-domains = [ "shoko" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "shoko" ];

    age-secrets =
      { environment, ... }:
      {
        age.secrets.shoko-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/shoko-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "shoko";
          };
        };
      };

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.shoko = {
          namespace = "media";

          helm.releases.shoko = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."shokoanime/server") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                  };
                  envFrom = [ ];
                  probes = {
                    liveness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/api/v3/Init/Status";
                      port = 8111;
                    };
                    readiness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/api/v3/Init/Status";
                      port = 8111;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                # bjw-s suffixes service names with the identifier once a controller owns >1 service
                # (main -> `shoko-main`), which would dangle the HTTPRoute backendRef; forceRename keeps `shoko`.
                forceRename = "shoko";
                ports.http.port = 8111;
              };

              persistence = {
                # Official image keeps its state in /home/shoko/.shoko (no /config).
                config = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "10Gi";
                  storageClass = "longhorn";
                  labels."recurring-job-group.longhorn.io/media-config" = "enabled";
                  globalMounts = [ { path = "/home/shoko/.shoko"; } ];
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
