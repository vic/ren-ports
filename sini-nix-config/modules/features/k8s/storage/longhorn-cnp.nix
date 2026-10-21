# Longhorn CiliumNetworkPolicies. Same aspect as longhorn.nix.
{ ... }:
let
  toPorts = ports: [
    {
      ports = map (port: {
        inherit port;
        protocol = "TCP";
      }) ports;
    }
  ];
in
{
  ren.aspects.k8s-storage-longhorn.k8s-manifests =
    { cluster, ... }:
    {
      applications.longhorn.resources.ciliumNetworkPolicies = {
        # Longhorn runs `longhorn system-backup`/backup mounts from the pod
        # netns, so reaching the NAS backupstore (an external/world IP) needs an
        # explicit egress allow - host-netns NFS (csi/kubelet) bypasses pod
        # policy, but this does not. NFSv4 = 2049/TCP; 111/TCP (rpcbind) for safety.
        allow-nas-backup-egress = {
          metadata.annotations."argocd.argoproj.io/sync-wave" = "-1";
          spec = {
            description = "Allow Longhorn pods to reach the NAS NFS backupstore.";
            endpointSelector.matchLabels."k8s:io.kubernetes.pod.namespace" = "longhorn-system";
            egress = [
              {
                toCIDR = [ "${cluster.nfsVolumes."longhorn-backups".server}/32" ];
                toPorts = toPorts [
                  "2049"
                  "111"
                ];
              }
            ];
          };
        };

        allow-kube-apiserver-egress = {
          metadata.annotations."argocd.argoproj.io/sync-wave" = "-1";
          spec = {
            description = "Allow Longhorn pods to talk to kube-apiserver.";
            endpointSelector.matchLabels."k8s:io.kubernetes.pod.namespace" = "longhorn-system";
            egress = [
              {
                toEntities = [ "kube-apiserver" ];
                toPorts = toPorts [
                  "443"
                  "6443"
                ];
              }
            ];
          };
        };

        # The chart's longhorn-manager NetworkPolicy admits only Longhorn's own
        # pods, so its ServiceMonitor scrape needs its own allow.
        allow-prometheus-ingress-longhorn-manager.spec = {
          description = "Allow prometheus to scrape longhorn-manager metrics (9500).";
          endpointSelector.matchLabels.app = "longhorn-manager";
          ingress = [
            {
              fromEndpoints = [
                {
                  matchLabels = {
                    "k8s:io.kubernetes.pod.namespace" = "monitoring";
                    "app.kubernetes.io/name" = "prometheus";
                  };
                }
              ];
              toPorts = toPorts [ "9500" ];
            }
          ];
        };
      };
    };
}
