# Grafana HTTPRoute, Secrets, CiliumNetworkPolicies. Same aspect as grafana.nix.
{ ren, ... }:
let
  toPorts = port: [
    {
      ports = [
        {
          inherit port;
          protocol = "TCP";
        }
      ];
    }
  ];
in
{
  ren.aspects.k8s-monitoring-grafana.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.grafana.resources = {
        httpRoutes.grafana.spec = {
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "grafana"}-https";
            }
          ];
          hostnames = [ (ren.helpers.clusterDomainFor cluster "grafana") ];
          rules = [
            {
              backendRefs = [
                {
                  name = "grafana";
                  port = 80;
                }
              ];
            }
          ];
        };

        secrets = {
          grafana-oidc-client-secret = {
            type = "Opaque";
            stringData.client-secret = config.age.secrets.grafana-oidc-client-secret.sopsRef;
          };

          grafana-admin = {
            type = "Opaque";
            stringData = {
              admin-user = "admin";
              admin-password = config.age.secrets.grafana-admin-password.sopsRef;
            };
          };

          grafana-secret-key = {
            type = "Opaque";
            stringData.secret-key = config.age.secrets.grafana-secret-key.sopsRef;
          };
        };

        ciliumNetworkPolicies = {
          # The dashboard sidecar watches ConfigMaps via the apiserver.
          allow-grafana-kube-apiserver-egress.spec = {
            description = "Allow the grafana dashboard sidecar to watch the kube-apiserver.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "grafana";
            egress = [
              {
                toEntities = [ "kube-apiserver" ];
                toPorts = toPorts "6443";
              }
            ];
          };

          # OIDC token/userinfo calls go server-side from the grafana pod
          # to kanidm, which lives outside the cluster (world entity).
          allow-grafana-kanidm-egress.spec = {
            description = "Allow grafana to reach kanidm for OIDC token/userinfo calls.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "grafana";
            egress = [
              {
                toEntities = [ "world" ];
                toPorts = toPorts "443";
              }
            ];
          };
        };
      };
    };
}
