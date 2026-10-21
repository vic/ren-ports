# llama-cpp network policies. In-cluster egress is covered by the clusterwide
# allow-internal-egress policy; only the off-cluster path and the ingress need
# stating. All select the shared engine label, so they cover every instance.
_:
let
  inherit (import ./_llama-cpp-shared.nix) port engineLabel engineValue;
  onPort = p: [
    {
      ports = [
        {
          port = toString p;
          protocol = "TCP";
        }
      ];
    }
  ];
in
{
  ren.aspects.k8s-ai-llama-cpp.k8s-manifests = { ... }: {
    applications.llama-cpp.resources.ciliumNetworkPolicies = {
      # Declaring any ingress rule flips these pods to ingress default-deny, so
      # both callers are enumerated. kubectl port-forward is unaffected — that
      # arrives from the node, which Cilium allows.
      allow-ingress-llama-cpp.spec = {
        description = "Allow hindsight and Prometheus to reach llama-cpp (8080).";
        endpointSelector.matchLabels.${engineLabel} = engineValue;
        ingress = [
          {
            fromEndpoints = [
              { matchLabels."app.kubernetes.io/name" = "hindsight"; }
              {
                matchLabels = {
                  "k8s:io.kubernetes.pod.namespace" = "monitoring";
                  "app.kubernetes.io/name" = "prometheus";
                };
              }
            ];
            toPorts = onPort port;
          }
        ];
      };

      # Off-cluster LAN callers reach these over the internal LoadBalancers.
      # Same reasoning as allow-lan-ingress-shoko: the whole private 10/8 rather
      # than per-host pins, covering both the externalTrafficPolicy=Local source
      # IP and any node SNAT.
      allow-lan-ingress-llama-cpp.spec = {
        description = "Allow private-LAN clients to reach llama-cpp on 8080 over the internal LoadBalancers.";
        endpointSelector.matchLabels.${engineLabel} = engineValue;
        ingress = [
          {
            fromCIDR = [ "10.0.0.0/8" ];
            toPorts = onPort port;
          }
        ];
      };

      # Model download only. Once the PVCs are warm this is dead weight and can
      # be dropped, at the cost of a manual re-seed on any model change.
      allow-huggingface-egress-llama-cpp.spec = {
        description = "Allow llama-cpp to fetch GGUF weights from HuggingFace.";
        endpointSelector.matchLabels.${engineLabel} = engineValue;
        egress = [
          {
            toEntities = [ "world" ];
            toPorts = onPort 443;
          }
        ];
      };
    };
  };
}
