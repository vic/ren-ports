# mas CNPs: Postgres, gateway/synapse ingress, synapse and kanidm egress.
_:
let
  tcp = p: {
    port = toString p;
    protocol = "TCP";
  };
  mkNetworkPolicy = description: rule: {
    spec = {
      inherit description;
      endpointSelector.matchLabels."app.kubernetes.io/name" = "matrix-authentication-service";
    }
    // rule;
  };
  synapse = { matchLabels."app.kubernetes.io/name" = "synapse"; };
in
{
  ren.aspects.k8s-communication-matrix-mas.k8s-manifests = { ... }: {
    applications.matrix-authentication-service.resources.ciliumNetworkPolicies = {
      allow-postgres-egress-mas = mkNetworkPolicy "Allow MAS to reach the matrix-pg CNPG cluster." {
        egress = [
          {
            toEndpoints = [ { matchLabels."cnpg.io/cluster" = "matrix-pg"; } ];
            toPorts = [ { ports = [ (tcp 5432) ]; } ];
          }
        ];
      };
      allow-gateway-ingress-mas = mkNetworkPolicy "Allow Envoy Gateway proxies and synapse to reach MAS." {
        ingress = [
          {
            fromEndpoints = [
              { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; }
              synapse
            ];
            toPorts = [ { ports = [ (tcp 8080) ]; } ];
          }
        ];
      };
      allow-synapse-egress-mas = mkNetworkPolicy "Allow MAS to provision users through Synapse." {
        egress = [
          {
            toEndpoints = [ synapse ];
            toPorts = [ { ports = [ (tcp 8008) ]; } ];
          }
        ];
      };
      allow-internet-egress-mas = mkNetworkPolicy "Allow MAS to reach kanidm." {
        egress = [
          {
            toEntities = [ "world" ];
            toPorts = [ { ports = [ (tcp 443) ]; } ];
          }
        ];
      };
    };
  };
}
