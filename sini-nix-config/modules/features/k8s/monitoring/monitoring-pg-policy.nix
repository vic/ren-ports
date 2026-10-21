# monitoring-pg CiliumNetworkPolicies. Same aspect as monitoring-pg.nix.
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
  ren.aspects.k8s-monitoring-pg.k8s-manifests.applications.monitoring-pg.resources.ciliumNetworkPolicies = {
    # CNPG instance pods (instance manager) talk to the kube-apiserver.
    allow-monitoring-pg-apiserver-egress = {
      metadata.annotations."argocd.argoproj.io/sync-wave" = "-1";
      spec = {
        description = "Allow monitoring-pg CNPG instance pods to talk to kube-apiserver.";
        endpointSelector.matchLabels."cnpg.io/cluster" = "monitoring-pg";
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

    # Creating an ingress policy flips the instance pods to ingress
    # default-deny, so every legitimate caller is enumerated here:
    # grafana (5432), peer replication (5432/8000), the cnpg-system
    # operator (8000), prometheus (9187 metrics).
    allow-monitoring-pg-internal.spec = {
      description = "monitoring-pg ingress: grafana (5432), peer replication (5432/8000), CNPG operator (8000), prometheus (9187).";
      endpointSelector.matchLabels."cnpg.io/cluster" = "monitoring-pg";
      ingress = [
        {
          fromEndpoints = [ { matchLabels."app.kubernetes.io/name" = "grafana"; } ];
          toPorts = toPorts [ "5432" ];
        }
        {
          fromEndpoints = [ { matchLabels."cnpg.io/cluster" = "monitoring-pg"; } ];
          toPorts = toPorts [
            "5432"
            "8000"
          ];
        }
        {
          fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "cnpg-system"; } ];
          toPorts = toPorts [ "8000" ];
        }
        {
          fromEndpoints = [ { matchLabels."app.kubernetes.io/name" = "prometheus"; } ];
          toPorts = toPorts [ "9187" ];
        }
      ];
    };
  };
}
