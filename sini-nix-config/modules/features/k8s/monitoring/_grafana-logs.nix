# Log-browsing dashboards authored here (community ones key off a job-based label
# schema; ours is namespace/pod/container). Imported by grafana-dashboards.nix.
let
  vars = import ./_grafana-loki-vars.nix;
  mkLogsDashboard = import ./_grafana-logs-lib.nix { inherit (vars) lokiDs searchVar; };
  inherit (vars) mkLabelVar;
in
{
    pod-logs = {
      folder = "Logs";
      dashboard = mkLogsDashboard {
        uid = "pod-logs";
        title = "Pod Logs";
        variables = [
          (mkLabelVar "namespace" "label_values(namespace)")
          (mkLabelVar "pod" "label_values({namespace=~\"$namespace\"}, pod)")
          (mkLabelVar "container" "label_values({namespace=~\"$namespace\", pod=~\"$pod\"}, container)")
        ];
        selector = "{namespace=~\"$namespace\", pod=~\"$pod\", container=~\"$container\"}";
        volumeBy = "pod";
      };
    };
    kubernetes-events = {
      folder = "Logs";
      dashboard = mkLogsDashboard {
        uid = "k8s-events";
        title = "Kubernetes Events";
        variables = [
          (mkLabelVar "namespace" "label_values({job=\"loki.source.kubernetes_events\"}, namespace)")
        ];
        selector = "{job=\"loki.source.kubernetes_events\", namespace=~\"$namespace\"}";
        volumeBy = "namespace";
      };
    };
    # Media file-tail logs: the per-app Alloy sidecars ship loki streams
    # labelled app/namespace + a static `log_file` (= app name). The raw
    # rotating `filename` label was dropped to bound stream cardinality,
    # and only the active info log is tailed (one logical file per app) —
    # so `app` IS the file provenance. `level` and free text are
    # filterable via the search box.
    media-logs = {
      folder = "Media";
      dashboard = mkLogsDashboard {
        uid = "media-logs";
        title = "Media Logs";
        variables = [
          (mkLabelVar "app" "label_values({namespace=\"media\"}, app)")
        ];
        # Require log_file → file-tail streams only; excludes the kept
        # sidecar (exportarr/logtail) stdout and any pre-fix streams.
        selector = "{namespace=\"media\", app=~\"$app\", log_file=~\".+\"}";
        volumeBy = "app";
      };
    };
}
