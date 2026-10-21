# PodMonitors for workloads whose charts ship no monitor of their own
# (gateway-helm has none). They live here in monitoring and select across
# namespaces; raw objects because there is no typed accessor without a
# kube-prometheus-stack crds bridge (planned alongside PrometheusRule authoring
# for alerting). Same aspect as prometheus.nix.
{ ... }:
{
  ren.aspects.k8s-monitoring-prometheus.k8s-manifests.applications.kube-prometheus-stack.objects = [
    {
      apiVersion = "monitoring.coreos.com/v1";
      kind = "PodMonitor";
      metadata = {
        name = "envoy-gateway";
        namespace = "monitoring";
      };
      spec = {
        namespaceSelector.matchNames = [ "envoy-gateway-system" ];
        selector.matchLabels."control-plane" = "envoy-gateway";
        podMetricsEndpoints = [ { port = "metrics"; } ];
      };
    }
    {
      apiVersion = "monitoring.coreos.com/v1";
      kind = "PodMonitor";
      metadata = {
        name = "envoy-proxies";
        namespace = "monitoring";
      };
      spec = {
        namespaceSelector.matchNames = [ "gateways" ];
        selector.matchLabels."app.kubernetes.io/component" = "proxy";
        # Envoy serves prometheus on the admin-style stats path, not
        # /metrics (the controller does use /metrics).
        podMetricsEndpoints = [
          {
            port = "metrics";
            path = "/stats/prometheus";
          }
        ];
      };
    }
  ];
}
