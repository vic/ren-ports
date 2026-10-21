# qBittorrent: BitTorrent client in one pod with a Gluetun WireGuard native sidecar (shared netns),
# so all qBittorrent egress goes through the VPN tunnel. UI on the gateway + OIDC (clientID stays
# "qbittorrent"). Split by concern: -vpn (gluetun, WG secrets, tun), -seed (qBittorrent.conf init),
# -portsync (forwarded-port sidecar), -logtail, -metrics, -net (CNPs), -route.
# Image: rolling LSIO `libtorrentv1` (libtorrent-v1 line), digest-pinned in images/linuxserver/qbittorrent.
{ ren, ... }:
{
  ren.aspects.k8s-media-qbittorrent = {
    service-domains = [ "qbittorrent" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "qbittorrent" ];

    age-secrets =
      { environment, ... }:
      {
        age.secrets.qbittorrent-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/qbittorrent-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "qbittorrent";
          };
        };
      };

    k8s-manifests =
      { charts, images, ... }:
      {
        applications.qbittorrent = {
          namespace = "media";

          helm.releases.qbittorrent = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";

                # Drives the cluster DaemonSet's stdout-drop for this pod's main container
                # (the logtail sidecar is the canonical log source).
                pod.labels."den.observability/file-tailed" = "true";

                containers.main = {
                  image = {
                    inherit (images."linuxserver/qbittorrent") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    # WEBUI_PORT tells the LSIO image which port to serve on.
                    WEBUI_PORT = "8080";
                    UMASK = "022";
                  };
                  envFrom = [ ];
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

                # scratch-local RWO -> /scratch (pins pod to the scratch node,
                # alongside sabnzbd / unpackerr). No /data mount.
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
