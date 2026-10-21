# Alloy DaemonSet release (pod log tailing). Same aspect as alloy.nix.
# Positions live on a hostPath so a pod restart doesn't re-ingest every log file.
{ ... }:
{
  ren.aspects.k8s-monitoring-alloy.k8s-manifests =
    { charts, ... }:
    {
      applications.alloy.helm.releases.alloy = {
        chart = charts.grafana.alloy;

        values = {
          serviceMonitor.enabled = true;

          controller = {
            type = "daemonset";
            volumes.extra = [
              {
                name = "alloy-data";
                hostPath = {
                  path = "/var/lib/alloy";
                  type = "DirectoryOrCreate";
                };
              }
            ];
          };

          alloy = {
            # /var/log/pods files are root-owned
            securityContext = {
              runAsUser = 0;
              runAsGroup = 0;
            };

            mounts = {
              varlog = true;
              extra = [
                {
                  name = "alloy-data";
                  mountPath = "/tmp/alloy";
                }
              ];
            };

            extraEnv = [
              {
                name = "NODE_NAME";
                valueFrom.fieldRef.fieldPath = "spec.nodeName";
              }
            ];

          };
        };
      };
    };
}
