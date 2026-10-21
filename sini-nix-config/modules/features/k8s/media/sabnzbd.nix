# SABnzbd: Usenet download client. UI on nzb.json64.dev (prod.nix services.sabnzbd.domain), OIDC
# clientID "sabnzbd". Scratch-local ONLY (RWO media-scratch-local -> /scratch, co-schedules with
# qbittorrent); no /data mount. API key is seeded into sabnzbd.ini by the init container in
# sabnzbd-seed.nix. Log-tail in sabnzbd-logtail.nix, exportarr+PodMonitor in sabnzbd-metrics.nix,
# CNPs in sabnzbd-net.nix, route/OIDC in sabnzbd-route.nix.
# Image: rolling LSIO `latest`, digest-pinned in images/linuxserver/sabnzbd.
{ ren, ... }:
{
  ren.aspects.k8s-media-sabnzbd = {
    service-domains = [ "sabnzbd" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "sabnzbd" ];

    age-secrets =
      { environment, ... }:
      {
        age.secrets.sabnzbd-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/sabnzbd-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "sabnzbd";
          };
        };
      };

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.sabnzbd = {
          namespace = "media";

          helm.releases.sabnzbd = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."linuxserver/sabnzbd") repository digest;
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
                      path = "/";
                      port = 8080;
                    };
                    readiness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/";
                      port = 8080;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 8080;
              };

              persistence = {
                config = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "1Gi";
                  storageClass = "longhorn";
                  labels."recurring-job-group.longhorn.io/media-config" = "enabled";
                  globalMounts = [ { path = "/config"; } ];
                };
                # scratch-local RWO -> /scratch (pins pod to the scratch node). No /data.
                scratch = {
                  type = "persistentVolumeClaim";
                  existingClaim = "media-scratch-local";
                  globalMounts = [ { path = "/scratch"; } ];
                };
              };
            };
          };
        };
      };
  };
}
