# Pinned upstream dashboards (core). Imported by grafana-dashboards.nix.
let
  envoyDashboardUrl =
    name:
    "https://raw.githubusercontent.com/envoyproxy/gateway/v1.8.1/charts/gateway-addons-helm/dashboards/${name}.json";
in
{
    argocd = {
      title = "ArgoCD";
      folder = "GitOps";
      url = "https://grafana.com/api/dashboards/14584/revisions/1/download";
      sha256 = "1ab8sdrd8ngaw4p9vzldzln5x1xqbp09wbmy9lkyv0gaxnl7nyqr";
      fixDatasource = true;
    };
    cert-manager = {
      title = "cert-manager";
      folder = "Security";
      url = "https://grafana.com/api/dashboards/11001/revisions/1/download";
      sha256 = "01q5ks0q3sabnw1rmmpz1yl864i47hbfxw0ksk6vpibrwm52p879";
      fixDatasource = true;
    };
    longhorn = {
      title = "Longhorn";
      folder = "Storage";
      url = "https://grafana.com/api/dashboards/13032/revisions/6/download";
      sha256 = "0rfdrixrj53czyxawvqf47z5rcgbiz2fr91ih9a7rj1n9akzhgvw";
      fixDatasource = true;
    };
    envoy-gateway = {
      title = "Envoy Gateway";
      folder = "Networking";
      url = envoyDashboardUrl "envoy-gateway-global";
      sha256 = "0knr3cgqf4cg31hk4ds39mywz1xpxxfirb886y2d42i7bdh2rp1c";
    };
    envoy-proxy = {
      title = "Envoy Proxy";
      folder = "Networking";
      url = envoyDashboardUrl "envoy-proxy-global";
      sha256 = "1dv7rgcmxap5cr7ww9q6icl0kwhjgaygs89acxgaqf7k1kcr40kz";
    };
    envoy-clusters = {
      title = "Envoy Clusters";
      folder = "Networking";
      url = envoyDashboardUrl "envoy-clusters";
      sha256 = "1ghh652xv48l72scyan0d2fjx9ll19kgx9xm3cifhqn5763mjvl9";
    };
    envoy-resources = {
      title = "Envoy Gateway Resources";
      folder = "Networking";
      url = envoyDashboardUrl "resources-monitor.gen";
      sha256 = "0h55cpc8k3294w8pjri6shkqqxscqnr8qs87k1dkhhk79xrmrzhl";
    };
}
