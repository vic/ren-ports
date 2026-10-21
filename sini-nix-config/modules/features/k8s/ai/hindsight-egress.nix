# hindsight egress policies. In-cluster LLM traffic rides the clusterwide
# allow-internal-egress policy. OFF-cluster endpoints do not: declaring any
# egress rule puts this pod in egress default-deny, so each external endpoint in
# use needs naming or Cilium silently drops it. Generated only for endpoints
# actually referenced by the settings.
{ lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests =
    { cluster, ... }:
    let
      llm = import ./_hindsight/llm.nix { inherit lib cluster; };
    in
    {
      applications.hindsight.resources.ciliumNetworkPolicies =
        lib.optionalAttrs (llm.usedExternals != [ ]) {
          allow-external-llm-egress-hindsight.spec = {
            description = "Allow hindsight to reach off-cluster LLM endpoints (e.g. llama-cpp on cortex-cuda).";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "hindsight";
            egress = map (e: {
              toCIDR = [ e.cidr ];
              toPorts = shared.tcp [ e.port ];
            }) llm.usedExternals;
          };
        }
        // {
          # World egress purely to populate the model cache on first boot.
          # Once the PVC is warm this is dead weight — a candidate to drop, or
          # to replace with an image that bakes the two models in.
          allow-huggingface-egress-hindsight.spec = {
            description = "Allow hindsight to fetch the local embedder/reranker from HuggingFace on first boot.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "hindsight";
            egress = [
              {
                toEntities = [ "world" ];
                toPorts = shared.tcp [ 443 ];
              }
            ];
          };
        };
    };
}
