# Grafana - Helm chart for in-cluster dashboards.
#
# Routed through the default gateway; auth is grafana-native OIDC against
# kanidm (client grafana), mapping kanidm groups to Grafana roles. Dashboards are
# provisioned by the sidecar from ConfigMaps labeled grafana_dashboard;
# kube-prometheus-stack force-deploys its standard dashboard set even
# with its bundled grafana disabled (see prometheus.nix).
# Split (same aspect): grafana-dashboards.nix, grafana-datasources.nix,
# grafana-ini.nix, grafana-resources.nix, grafana-secrets.nix.
{ ren, ... }:
{
  ren.aspects.k8s-monitoring-grafana = {
    # The fleet's Grafana, at grafana.<domain> (DNS record + gateway listener).
    service-domains = [ "grafana" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "grafana" ];

    k8s-manifests =
      { charts, ... }:
      {
        applications.grafana = {
          namespace = "monitoring";

          # Dashboard ConfigMaps (the CNPG one is ~250KiB) blow past the
          # 256KiB last-applied annotation limit under client-side apply.
          syncPolicy.syncOptions.serverSideApply = true;
          compareOptions.serverSideDiff = true;

          # CNPG cluster dashboard - rendered as a labeled ConfigMap the
          # sidecar picks up. The operator chart's grafanaDashboard.create is
          # a stub (the JSON moved to the dedicated dashboards repo this
          # chart is pinned from).
          helm.releases.cnpg-grafana-cluster = {
            chart = charts.cnpg-grafana-dashboards.cluster;
            values.grafanaDashboard.annotations.grafana_folder = "Databases";
          };

          helm.releases.grafana = {
            chart = charts.grafana.grafana;

            values = {
              # State lives in monitoring-pg (see monitoring-pg.nix);
              # dashboards/datasources are fully provisioned, so the pod is
              # stateless: no PVC, rolling updates are safe.
              persistence.enabled = false;

              # Without this the chart mints a render-time random admin
              # password - rotated on EVERY sync while the database keeps the
              # first-boot value: local admin unusable, sidecar reload 401s,
              # and perpetual SopsSecret drift in the diffs.
              admin = {
                existingSecret = "grafana-admin";
                userKey = "admin-user";
                passwordKey = "admin-password";
              };

              serviceMonitor.enabled = true;

              # Provision dashboards from labeled ConfigMaps; the
              # grafana_folder annotation routes each into a real folder.
              sidecar.dashboards = {
                enabled = true;
                searchNamespace = "monitoring";
                folderAnnotation = "grafana_folder";
                provider.foldersFromFilesStructure = true;
                # No credentialed reload POSTs - there is no password-bearing
                # account to authenticate them; the file provider polls.
                skipReload = true;
              };

              # Secrets land as env vars (GF_ vars override grafana.ini),
              # sourced from SopsSecrets / the CNPG role secret.
              envValueFrom = {
                GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET.secretKeyRef = {
                  name = "grafana-oidc-client-secret";
                  key = "client-secret";
                };
                GF_DATABASE_PASSWORD.secretKeyRef = {
                  name = "monitoring-pg-grafana-password";
                  key = "password";
                };
                GF_SECURITY_SECRET_KEY.secretKeyRef = {
                  name = "grafana-secret-key";
                  key = "secret-key";
                };
              };
            };
          };
        };
      };
  };
}
