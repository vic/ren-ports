# Prometheus/Alertmanager exposure (HTTPRoute + OIDC SecurityPolicy + Secrets) and
# PodMonitors. Same aspect as prometheus.nix.
{ ren, lib, ... }:
let
  uis = [
    "prometheus"
    "alertmanager"
  ];
  backends = {
    prometheus = {
      name = "kube-prometheus-stack-prometheus";
      port = 9090;
    };
    alertmanager = {
      name = "kube-prometheus-stack-alertmanager";
      port = 9093;
    };
  };
in
{
  ren.aspects.k8s-monitoring-prometheus.k8s-manifests =
    { cluster, config, ... }:
    {
      applications.kube-prometheus-stack = {
        resources.httpRoutes = lib.genAttrs uis (ui: {
          spec = {
            hostnames = [ (ren.helpers.clusterDomainFor cluster ui) ];
            # API-server defaults stated explicitly: this app's diff
            # otherwise keeps the routes OutOfSync after every sync.
            parentRefs = [
              {
                group = "gateway.networking.k8s.io";
                kind = "Gateway";
                name = "default-gateway";
                namespace = "gateways";
                sectionName = "${ren.helpers.domainForResource cluster ui}-https";
              }
            ];
            rules = [
              {
                matches = [
                  {
                    path = {
                      type = "PathPrefix";
                      value = "/";
                    };
                  }
                ];
                backendRefs = [
                  (
                    backends.${ui}
                    // {
                      group = "";
                      kind = "Service";
                      weight = 1;
                    }
                  )
                ];
              }
            ];
          };
        });

        resources.securityPolicies = lib.mapAttrs' (
          ui: _:
          lib.nameValuePair "${ui}-oidc" {
            spec = {
              targetRefs = [
                {
                  group = "gateway.networking.k8s.io";
                  kind = "HTTPRoute";
                  name = ui;
                }
              ];
              oidc = {
                provider = ren.helpers.oidcProviderFor cluster ui;
                clientID = ui;
                clientSecret.name = "${ui}-oidc-client-secret";
                scopes = [
                  "email"
                  "openid"
                  "profile"
                ];
              };
            };
          }
        ) backends;

        resources.secrets = lib.genAttrs (map (ui: "${ui}-oidc-client-secret") uis) (name: {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.${name}.sopsRef;
        });
      };
    };
}
