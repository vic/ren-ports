# Tdarr: distributed transcoding. Server (UI, library DB, job orchestrator, internalNode=false) scans the
# NAS read-only and hands jobs to tdarr-node workers on its node port 8266. Ports: 8265 webUI (routed +
# OIDC), 8266 node channel; Service publishes both, `http` primary. Config on one longhorn RWO PVC
# (/app/server, /app/configs, /app/logs). Metrics/CNPs in tdarr-metrics.nix / tdarr-net.nix, route in
# tdarr-route.nix, node DaemonSet in tdarr-node.nix.
{ ren, ... }:
{
  ren.aspects.k8s-media-tdarr = {
    service-domains = [ "tdarr" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "tdarr" ];
    k8s-manifests =
      { charts, images, ... }:
      {
        applications.tdarr = {
          namespace = "media";

          helm.releases.tdarr = {
            chart = charts.bjw-s-labs.app-template;
            values = {
              controllers.main = {
                type = "deployment";
                # Single-writer DB on an RWO PVC: tear the old pod down before the
                # new one mounts /app/server.
                strategy = "Recreate";

                containers.main = {
                  image = {
                    inherit (images."haveagitgat/tdarr") repository digest;
                  };
                  env = {
                    TZ = "America/Los_Angeles";
                    PUID = "1027";
                    PGID = "65536";
                    inContainer = "true";
                    # Server orchestrates only; transcoding is the nodes' job.
                    internalNode = "false";
                    serverIP = "0.0.0.0";
                    serverPort = "8266";
                    webUIPort = "8265";
                  };
                  probes = {
                    liveness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/";
                      port = 8265;
                    };
                    readiness = {
                      enabled = true;
                      type = "HTTP";
                      path = "/";
                      port = 8265;
                    };
                  };
                };
              };

              service.main = {
                controller = "main";
                ports.http = {
                  port = 8265;
                  primary = true;
                };
                ports.node = {
                  port = 8266;
                };
              };

              persistence = {
                # Server DB + configs + logs on one longhorn RWO PVC.
                config = {
                  type = "persistentVolumeClaim";
                  accessMode = "ReadWriteOnce";
                  size = "5Gi";
                  storageClass = "longhorn";
                  labels."recurring-job-group.longhorn.io/media-config" = "enabled";
                  globalMounts = [
                    { path = "/app/server"; }
                    { path = "/app/configs"; }
                    { path = "/app/logs"; }
                  ];
                };
                # NAS library over NFS, read-only: the server only scans it.
                data = {
                  type = "persistentVolumeClaim";
                  existingClaim = "media-data-nfs";
                  globalMounts = [
                    {
                      path = "/data";
                      readOnly = true;
                    }
                  ];
                };
              };
            };
          };
        };
      };
  };
}
