# hindsight-pg network policies.
{ ... }:
let
  tcp = ports: [
    {
      ports = map (p: {
        port = toString p;
        protocol = "TCP";
      }) ports;
    }
  ];
in
{
  ren.aspects.k8s-ai-hindsight-pg.k8s-manifests.applications.hindsight-pg.resources.ciliumNetworkPolicies = {
    # CNPG instance pods (instance manager) talk to the kube-apiserver.
    allow-hindsight-pg-apiserver-egress = {
      metadata.annotations."argocd.argoproj.io/sync-wave" = "-1";
      spec = {
        description = "Allow hindsight-pg CNPG instance pods to talk to kube-apiserver.";
        endpointSelector.matchLabels."cnpg.io/cluster" = "hindsight-pg";
        egress = [
          {
            toEntities = [ "kube-apiserver" ];
            toPorts = tcp [
              443
              6443
            ];
          }
        ];
      };
    };

    # Creating an ingress policy flips the instance pods to ingress
    # default-deny, so every legitimate caller is enumerated here:
    # hindsight (5432), peer replication (5432/8000), the cnpg-system
    # operator (8000), prometheus (9187 metrics).
    allow-hindsight-pg-internal.spec = {
      description = "hindsight-pg ingress: hindsight (5432), peer replication (5432/8000), CNPG operator (8000), prometheus (9187).";
      endpointSelector.matchLabels."cnpg.io/cluster" = "hindsight-pg";
      ingress = [
        {
          fromEndpoints = [ { matchLabels."app.kubernetes.io/name" = "hindsight"; } ];
          toPorts = tcp [ 5432 ];
        }
        {
          fromEndpoints = [ { matchLabels."cnpg.io/cluster" = "hindsight-pg"; } ];
          toPorts = tcp [
            5432
            8000
          ];
        }
        {
          fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "cnpg-system"; } ];
          toPorts = tcp [ 8000 ];
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
          toPorts = tcp [ 9187 ];
        }
      ];
    };
  };
}
