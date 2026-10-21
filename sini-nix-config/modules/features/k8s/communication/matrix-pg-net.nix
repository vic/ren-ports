# matrix-pg metrics PodMonitor and CNPs.
{ ... }:
let
  tcp = ports: map (p: { port = toString p; protocol = "TCP"; }) ports;
in
{
  ren.aspects.k8s-communication-matrix-pg.k8s-manifests = { ... }: {
    applications.matrix-pg = {
      # Manual metrics PodMonitor, replacing CNPG's deprecated
      # monitoring.enablePodMonitor. Relabels `instance` to the stable pod
      # name (matrix-pg-1/2) instead of the ephemeral pod IP:port.
      objects = [
        {
          apiVersion = "monitoring.coreos.com/v1";
          kind = "PodMonitor";
          metadata = {
            name = "matrix-pg-metrics";
            namespace = "matrix";
          };
          spec = {
            selector.matchLabels = {
              "cnpg.io/cluster" = "matrix-pg";
              "cnpg.io/podRole" = "instance";
            };
            podMetricsEndpoints = [
              {
                port = "metrics";
                relabelings = [
                  {
                    sourceLabels = [ "__meta_kubernetes_pod_name" ];
                    targetLabel = "instance";
                  }
                ];
              }
            ];
          };
        }
      ];

      resources.ciliumNetworkPolicies = {
        # CNPG instance pods (instance manager) talk to the kube-apiserver.
        allow-matrix-pg-apiserver-egress = {
          metadata.annotations."argocd.argoproj.io/sync-wave" = "-1";
          spec = {
            description = "Allow matrix-pg CNPG instance pods to talk to kube-apiserver.";
            endpointSelector.matchLabels."cnpg.io/cluster" = "matrix-pg";
            egress = [
              {
                toEntities = [ "kube-apiserver" ];
                toPorts = [ { ports = tcp [ 443 6443 ]; } ];
              }
            ];
          };
        };

        # Creating an ingress policy flips the instance pods to ingress
        # default-deny, so every legitimate caller is enumerated here:
        # synapse and MAS (5432), peer replication (5432/8000), the
        # cnpg-system operator (8000), prometheus (9187 metrics).
        allow-matrix-pg-internal.spec = {
          description = "matrix-pg ingress: synapse and MAS (5432), peer replication (5432/8000), CNPG operator (8000), prometheus (9187).";
          endpointSelector.matchLabels."cnpg.io/cluster" = "matrix-pg";
          ingress = [
            {
              fromEndpoints = [
                { matchLabels."app.kubernetes.io/name" = "synapse"; }
                { matchLabels."app.kubernetes.io/name" = "matrix-authentication-service"; }
              ];
              toPorts = [ { ports = tcp [ 5432 ]; } ];
            }
            {
              fromEndpoints = [ { matchLabels."cnpg.io/cluster" = "matrix-pg"; } ];
              toPorts = [ { ports = tcp [ 5432 8000 ]; } ];
            }
            {
              fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "cnpg-system"; } ];
              toPorts = [ { ports = tcp [ 8000 ]; } ];
            }
            {
              fromEndpoints = [
                {
                  matchLabels = {
                    "k8s:io.kubernetes.pod.namespace" = "monitoring";
                    "app.kubernetes.io/name" = "prometheus";
                  };
                }
              ];
              toPorts = [ { ports = tcp [ 9187 ]; } ];
            }
          ];
        };
      };
    };
  };
}
