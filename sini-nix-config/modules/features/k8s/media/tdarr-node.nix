# Tdarr node-worker DaemonSet: one pod per AMD-APU axon node (nodeSelector node.kubernetes.io/amd-gpu),
# each claiming the node's GPU (amd.com/gpu: 1) to hardware-encode AV1 with the custom registry image.
# Reads the library over NFS at /data (writable: the node writes the transcode back), caches the
# in-flight transcode on a node-local emptyDir at /temp, and dials tdarr.media.svc:8266 for jobs.
{ ... }:
{
  ren.aspects.k8s-media-tdarr.k8s-manifests =
    { charts, images, ... }:
    {
      applications.tdarr-node = {
        namespace = "media";

        helm.releases.tdarr-node = {
          chart = charts.bjw-s-labs.app-template;
          values = {
            controllers.main = {
              type = "daemonset";
              pod.nodeSelector."node.kubernetes.io/amd-gpu" = "true";

              containers.main = {
                image = {
                  inherit (images."json64/tdarr-node") repository digest;
                };
                env = {
                  TZ = "America/Los_Angeles";
                  PUID = "1027";
                  PGID = "65536";
                  inContainer = "true";
                  serverIP = "tdarr.media.svc.cluster.local";
                  serverPort = "8266";
                  # Per-host node name so the server tracks each DaemonSet pod as its own GPU worker.
                  # A static value makes all three register under one name (server warns "nodeName ...
                  # used by multiple Nodes") and muddles per-node worker assignment + stats.
                  nodeName.valueFrom.fieldRef.fieldPath = "spec.nodeName";
                  nodeType = "mapped";
                  transcodegpuWorkers = "1";
                  transcodecpuWorkers = "0";
                  healthcheckgpuWorkers = "0";
                  healthcheckcpuWorkers = "0";
                };
                resources = {
                  requests."amd.com/gpu" = 1;
                  limits."amd.com/gpu" = 1;
                };
              };
            };

            persistence = {
              # NAS library over NFS, writable: the node writes the finished transcode back.
              data = {
                type = "persistentVolumeClaim";
                existingClaim = "media-data-nfs";
                globalMounts = [ { path = "/data"; } ];
              };
              # Node-local transcode scratch: in-flight work cache, never leaves the node.
              temp = {
                type = "emptyDir";
                globalMounts = [ { path = "/temp"; } ];
              };
            };
          };
        };

        resources.ciliumNetworkPolicies = {
          # tdarr-node dials the server's node-worker control port (8266) in the same media namespace.
          allow-nodeconn-egress-tdarr-node.spec = {
            description = "Allow tdarr-node workers to reach the tdarr server node port (8266).";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "tdarr-node";
            egress = [
              {
                toEndpoints = [
                  { matchLabels."app.kubernetes.io/name" = "tdarr"; }
                ];
                toPorts = [
                  {
                    ports = [
                      {
                        port = "8266";
                        protocol = "TCP";
                      }
                    ];
                  }
                ];
              }
            ];
          };

          # Ingress lockdown: network-policy.nix doesn't manage tdarr-node, so restore the default-deny
          # it would otherwise inherit (mirrors unpackerr). The node takes no real inbound; only the
          # host entity (kubelet probes / node-local) is allowed.
          deny-ingress-tdarr-node.spec = {
            description = "Default-deny ingress for tdarr-node (host-only).";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "tdarr-node";
            enableDefaultDeny.ingress = true;
            ingress = [ { fromEntities = [ "host" ]; } ];
          };
        };
      };
    };
}
