# hindsight dataplane probes.
{ lib, ... }:
let
  shared = import ./_hindsight/shared.nix { inherit lib; };
  inherit (shared) port;
in
{
  ren.aspects.k8s-ai-hindsight.k8s-manifests.applications.hindsight.helm.releases.hindsight.values.controllers.main.containers.main.probes =
    {
      # /health is the readiness endpoint; /health/live the
      # liveness one (upstream chart's split).
      liveness = {
        enabled = true;
        type = "HTTP";
        path = "/health/live";
        inherit port;
      };
      readiness = {
        enabled = true;
        type = "HTTP";
        path = "/health";
        inherit port;
      };
      # First boot downloads the embedder + reranker from
      # HuggingFace into the (empty) model-cache PVC before the
      # API serves anything; 10 minutes of headroom keeps the
      # liveness probe from killing the pod mid-download.
      startup = {
        enabled = true;
        custom = true;
        spec = {
          httpGet = {
            path = "/health";
            inherit port;
          };
          periodSeconds = 10;
          failureThreshold = 60;
        };
      };
    };
}
