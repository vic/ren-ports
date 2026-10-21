# Garage web UI (noooste/garage-ui) - the operator/bucket/key admin console.
# The chart's own auth (config.auth.oidc / config.auth.admin) is left DISABLED
# (values defaults): the UI serves unauthenticated and the Envoy Gateway kanidm
# OIDC SecurityPolicy (garage-ui-route.nix) is the sole security boundary. The UI
# drives the Garage admin API (3903) with the shared admin token.
#
# Chart surface pinned against garage-ui v0.8.4:
#   - admin endpoint -> config.garage.admin_endpoint
#   - admin token    -> env GARAGE_UI_GARAGE_ADMIN_TOKEN from
#                       config.garage.existingSecret.{name,key}
#   - Service        -> name "garage-ui", port 80
#   - pod label      -> app.kubernetes.io/name = garage-ui
{ ren, ... }:
{
  ren.aspects.k8s-storage-garage-ui = {
    service-domains = [ "garage-ui" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "garage-ui" ];

    age-secrets =
      { cluster, environment, ... }:
      {
        # JWT signing key for the UI's own session cookies. Owned here rather
        # than left to the chart: its secret template mints one with
        # `genPrivateKey "ed25519"` guarded by a `lookup`, and `lookup` always
        # returns empty under `helm template` (how nixidy renders), so every
        # full nixidy-sync minted a NEW key, silently rotating the live one and
        # dropping every session. Cluster-scoped like the other garage secrets.
        age.secrets.garage-ui-jwt-key = {
          rekeyFile = cluster.secretPath + "/garage/ui-jwt-key.age";
          generator.script = "ed25519-private-key";
          sopsOutput = {
            file = "garage";
            key = "ui-jwt-key";
          };
        };

        # Shares its rekeyFile + generator with the kanidm garage-ui client's
        # basicSecretFile, so both sides resolve to the same value (the longhorn
        # idiom). This declares the cluster (sops) half.
        age.secrets.garage-ui-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/garage-ui-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "garage-ui";
          };
        };
      };

    k8s-manifests =
      { cluster, charts, ... }:
      let
        uiHost = ren.helpers.clusterDomainFor cluster "garage-ui";
      in
      {
        # Merges into the shared garage application (namespace anchored in
        # garage-cluster.nix). This aspect is the first to add a helm release to it.
        applications.garage.helm.releases.garage-ui = {
          chart = charts.noooste.garage-ui;
          values.config = {
            # Point the chart at the Secret declared in garage-ui-route.nix.
            # Setting this name switches OFF both of the chart's jwt-key emit
            # branches, so the key is ours end to end and stable across renders.
            auth.jwt_private_key_secret = {
              name = "garage-ui-jwt-key";
              key = "jwt-key.pem";
            };
            server = {
              # Informational external URL (only required by the chart's own OIDC).
              root_url = "https://${uiHost}";
              domain = uiHost;
            };
            garage = {
              endpoint = "http://garage.garage.svc:3900";
              region = "garage";
              # The operator's own `garage` Service exposes admin on :3903.
              admin_endpoint = "http://garage.garage.svc:3903";
              # Admin bearer token from the agenix->sops garage-admin-token Secret.
              existingSecret = {
                name = "garage-admin-token";
                key = "admin-token";
              };
            };
          };
        };
      };
  };
}
