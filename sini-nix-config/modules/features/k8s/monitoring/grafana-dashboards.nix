# Grafana dashboards rendered as sidecar ConfigMaps with a grafana_folder
# annotation: pinned imports (build-time transformed) + locally authored Loki
# log dashboards. Same aspect as grafana.nix. Helpers: _grafana-*.nix.
{ lib, ... }:
{
  ren.aspects.k8s-monitoring-grafana.k8s-manifests =
    { pkgs, ... }:
    let
      mkDashboardJson = import ./_grafana-dashboard-json.nix { inherit lib pkgs; };
      importedDashboards = import ./_grafana-imported.nix // import ./_grafana-imported-media.nix;
      localDashboards = import ./_grafana-logs.nix;
    in
    {
      applications.grafana.resources.configMaps =
        lib.mapAttrs' (
          name: d:
          lib.nameValuePair "dashboard-${name}" {
            metadata = {
              labels.grafana_dashboard = "1";
              annotations.grafana_folder = d.folder;
            };
            data."${name}.json" = mkDashboardJson {
              inherit name;
              inherit (d) title url sha256;
              fixDatasource = d.fixDatasource or false;
              excludeColonInstances = d.excludeColonInstances or false;
            };
          }
        ) importedDashboards
        // lib.mapAttrs' (
          name: d:
          lib.nameValuePair "dashboard-${name}" {
            metadata = {
              labels.grafana_dashboard = "1";
              annotations.grafana_folder = d.folder;
            };
            data."${name}.json" = builtins.toJSON d.dashboard;
          }
        ) localDashboards;
    };
}
