# synapse CNPs: gateway ingress, MAS both ways, Postgres and federation egress.
_:
let
  tcp = p: {
    port = toString p;
    protocol = "TCP";
  };
  mkNetworkPolicy = description: rule: {
    spec = {
      inherit description;
      endpointSelector.matchLabels."app.kubernetes.io/name" = "synapse";
    }
    // rule;
  };
  mas = { matchLabels."app.kubernetes.io/name" = "matrix-authentication-service"; };
in
{
  ren.aspects.k8s-communication-matrix-synapse.k8s-manifests = { ... }: {
    applications.synapse.resources.ciliumNetworkPolicies = {
      allow-gateway-ingress-synapse = mkNetworkPolicy "Allow Envoy Gateway proxies to reach synapse." {
        ingress = [
          {
            fromEndpoints = [ { matchLabels."k8s:io.kubernetes.pod.namespace" = "gateways"; } ];
            toPorts = [ { ports = [ (tcp 8008) ]; } ];
          }
        ];
      };
      allow-mas-egress-synapse = mkNetworkPolicy "Allow synapse to introspect tokens at MAS." {
        egress = [
          {
            toEndpoints = [ mas ];
            toPorts = [ { ports = [ (tcp 8080) ]; } ];
          }
        ];
      };
      allow-mas-ingress-synapse = mkNetworkPolicy "Allow MAS to provision users through Synapse." {
        ingress = [
          {
            fromEndpoints = [ mas ];
            toPorts = [ { ports = [ (tcp 8008) ]; } ];
          }
        ];
      };
      allow-postgres-egress-synapse = mkNetworkPolicy "Allow synapse to reach the matrix-pg CNPG cluster." {
        egress = [
          {
            toEndpoints = [ { matchLabels."cnpg.io/cluster" = "matrix-pg"; } ];
            toPorts = [ { ports = [ (tcp 5432) ]; } ];
          }
        ];
      };
      # 443 and 8448: federation peers (8448 for those that do not delegate to 443).
      allow-internet-egress-synapse = mkNetworkPolicy "Allow synapse to reach federation peers." {
        egress = [
          {
            toEntities = [ "world" ];
            toPorts = [
              {
                ports = [
                  (tcp 443)
                  (tcp 8448)
                ];
              }
            ];
          }
        ];
      };
    };
  };
}
