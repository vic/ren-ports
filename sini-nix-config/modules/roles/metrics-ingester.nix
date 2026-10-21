{ ren, ... }:
{
  ren.aspects.metrics-ingester = {
    includes = with ren.aspects; [
      svc-monitoring-prometheus
      svc-monitoring-loki
      svc-monitoring-grafana
    ];
  };
}
