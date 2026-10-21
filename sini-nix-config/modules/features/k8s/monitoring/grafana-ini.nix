# grafana.ini: server, security, monitoring-pg backing store, kanidm OIDC.
# Same aspect as grafana.nix.
{ ren, ... }:
{
  ren.aspects.k8s-monitoring-grafana.k8s-manifests =
    { cluster, ... }:
    let
      domain = ren.helpers.clusterDomainFor cluster "grafana";
      kanidmDomain = ren.helpers.clusterDomainFor cluster "kanidm";
    in
    {
      applications.grafana.helm.releases.grafana.values."grafana.ini" = {
        server = {
          inherit domain;
          root_url = "https://${domain}";
          enforce_domain = false;
        };

        # Passwordless, mirroring the host-level grafana: no admin
        # user is ever created, so the login form stays harmless and
        # kanidm is the only authority (server-admins map to
        # GrafanaAdmin). secret_key is pinned via env above — the
        # stateless pod must not sign cookies with the shipped
        # default.
        security = {
          disable_initial_admin_creation = true;
          cookie_secure = true;
          disable_gravatar = true;
          hide_version = true;
        };

        # Backing store in monitoring-pg (password via
        # GF_DATABASE_PASSWORD above). ssl_mode require: CNPG serves
        # TLS with a cluster-internal CA.
        database = {
          type = "postgres";
          host = "monitoring-pg-rw.monitoring:5432";
          name = "grafana";
          user = "grafana";
          ssl_mode = "require";
        };

        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
        };

        users = {
          allow_sign_up = false;
          auto_assign_org = true;
          auto_assign_org_role = "Viewer";
        };

        auth.oauth_auto_login = true;

        # Mirrors the host-level grafana OIDC config (same kanidm
        # ACL groups: grafana.{editors,admins,server-admins}).
        "auth.generic_oauth" = {
          enabled = true;
          name = "KanIDM";
          icon = "signin";
          allow_sign_up = true;
          auto_login = true;
          client_id = "grafana";
          scopes = "openid email profile";
          login_attribute_path = "preferred_username";
          auth_url = "https://${kanidmDomain}/ui/oauth2";
          token_url = "https://${kanidmDomain}/oauth2/token";
          api_url = "https://${kanidmDomain}/oauth2/openid/grafana/userinfo";
          use_pkce = true;
          use_refresh_token = true;
          role_attribute_path = "contains(groups[*], 'server_admin') && 'GrafanaAdmin' || contains(groups[*], 'admin') && 'Admin' || contains(groups[*], 'editor') && 'Editor' || 'Viewer'";
          role_attribute_strict = false;
          allow_assign_grafana_admin = true;
          skip_org_role_sync = false;
        };
      };
    };
}
