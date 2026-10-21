# Grafana age-secrets (OIDC client, admin password, cookie secret key). Same aspect as grafana.nix.
{ ... }:
{
  ren.aspects.k8s-monitoring-grafana.age-secrets =
    { environment, ... }:
    {
      age.secrets.grafana-oidc-client-secret = {
        rekeyFile = environment.secretPath + "/oidc/grafana-oidc-client-secret.age";
        generator = {
          tags = [ "oidc" ];
          script = "rfc3986-secret";
        };
        sopsOutput = {
          file = "oidc";
          key = "grafana";
        };
      };

      # The admin secret stays pinned but is inert: with
      # disable_initial_admin_creation no account exists to use it, and
      # removing it would regress the chart to render-time random
      # passwords (diff churn).
      age.secrets.grafana-admin-password = {
        rekeyFile = environment.secretPath + "/grafana/admin-password.age";
        generator.script = "rfc3986-secret";
        sopsOutput = {
          file = "grafana";
          key = "admin-password";
        };
      };

      age.secrets.grafana-secret-key = {
        rekeyFile = environment.secretPath + "/grafana/secret-key.age";
        settings.length = "32";
        generator.script = "hex";
        sopsOutput = {
          file = "grafana";
          key = "secret-key";
        };
      };
    };
}
