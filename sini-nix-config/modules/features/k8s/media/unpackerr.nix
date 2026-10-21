# Unpackerr: extracts completed (rar/zip) downloads for the *arr stack. No web UI (no route, no OIDC),
# stateless (env-only config, no /config PVC). Scratch-local RWO at /scratch co-schedules it with
# qBittorrent/SABnzbd so it sees completed torrents in place. One env block per *arr instance
# (in-namespace short service names) with keys from media-arr-api-keys. Metrics/CNPs in
# unpackerr-metrics.nix. Image: rolling golift `latest`, digest-pinned in images/golift/unpackerr.
{ ... }:
{
  ren.aspects.k8s-media-unpackerr = {
    service-domains = [ ];

    k8s-manifests =
      { charts, images, ... }:
      let
        completePath = "/scratch/torrents/complete";

        apiKey = key: {
          valueFrom.secretKeyRef = {
            name = "media-arr-api-keys";
            inherit key;
          };
        };

        # One env block per *arr instance (index 0).
        arrEnv = prefix: key: url: {
          "UN_${prefix}_0_URL" = url;
          "UN_${prefix}_0_API_KEY" = apiKey key;
          "UN_${prefix}_0_PATHS_0" = completePath;
        };
      in
      {
        applications.unpackerr = {
          namespace = "media";

          helm.releases.unpackerr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";
                containers.main = {
                  image = {
                    inherit (images."golift/unpackerr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    UN_LOG_QUEUES = "1m";
                    # Built-in prometheus webserver: served at /metrics on 5656.
                    UN_WEBSERVER_METRICS = "true";
                    UN_WEBSERVER_LISTEN_ADDR = "0.0.0.0:5656";
                  }
                  // arrEnv "SONARR" "sonarr" "http://sonarr:8989"
                  // arrEnv "RADARR" "radarr" "http://radarr:7878"
                  // arrEnv "LIDARR" "lidarr" "http://lidarr:8686"
                  // arrEnv "WHISPARR" "whisparr" "http://whisparr:6969";
                  envFrom = [ ];
                  # Named container port so the PodMonitor can reference it by name (the chart's
                  # service.main targetPort is numeric only).
                  ports = [
                    {
                      name = "metrics";
                      containerPort = 5656;
                    }
                  ];
                };
              };

              service.main = {
                controller = "main";
                ports.http.port = 5656;
              };

              # Same completed-torrents view as qBittorrent on the scratch node.
              persistence.scratch = {
                type = "persistentVolumeClaim";
                existingClaim = "media-scratch-local";
                globalMounts = [ { path = "/scratch"; } ];
              };
            };
          };
        };
      };
  };
}
