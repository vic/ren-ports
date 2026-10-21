# One PodMonitor for every llama-cpp instance: selected by the shared engine
# label, with `instance` taken from the per-release app name.
_:
let
  inherit (import ./_llama-cpp-shared.nix) engineLabel engineValue;
in
{
  ren.aspects.k8s-ai-llama-cpp.k8s-manifests = { ... }: {
    applications.llama-cpp.objects = [
      {
        apiVersion = "monitoring.coreos.com/v1";
        kind = "PodMonitor";
        metadata = {
          name = "llama-cpp";
          namespace = "ai";
        };
        spec = {
          selector.matchLabels.${engineLabel} = engineValue;
          podMetricsEndpoints = [
            {
              port = "http";
              path = "/metrics";
              interval = "30s";
              relabelings = [
                {
                  sourceLabels = [ "__meta_kubernetes_pod_label_app_kubernetes_io_name" ];
                  targetLabel = "instance";
                }
              ];
            }
          ];
        };
      }
    ];
  };
}
