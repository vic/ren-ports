# mas config.yaml (ConfigMap): listeners, Synapse link, kanidm upstream, admins.
{ ren, lib, ... }:
let
  adminGroup = "admins";
  # Upstream provider id, also in kanidm's redirect URL. Permanent.
  kanidmProviderId = "01M4YHS31NGAA65EM4FZ07BJZ4";
  masConfig =
    cluster: admins: {
      http = {
        public_base = "https://${ren.helpers.clusterDomainFor cluster "matrix-auth"}/";
        listeners = [
          {
            name = "web";
            resources = map (n: { name = n; }) [
              "discovery"
              "human"
              "oauth"
              "compat"
              "graphql"
              "assets"
              "health"
            ];
            binds = [ { address = "[::]:8080"; } ];
          }
        ];
      };
      matrix = {
        kind = "synapse";
        homeserver = "json64.dev";
        endpoint = "http://synapse.matrix.svc.cluster.local:8008";
        secret_file = "/secrets/shared-secret";
      };
      secrets = {
        encryption_file = "/secrets/encryption-key";
        keys = [ { key_file = "/secrets/signing.key"; } ];
      };
      passwords = {
        enabled = false;
        schemes = [
          {
            version = 1;
            algorithm = "bcrypt";
            unicode_normalization = true;
          }
          {
            version = 2;
            algorithm = "argon2id";
          }
        ];
      };
      policy.data.admin_users = admins;
      upstream_oauth2.providers = [
        {
          id = kanidmProviderId;
          synapse_idp_id = "oidc-kanidm"; # as Synapse stores idp_id `kanidm`
          human_name = "json64 (kanidm)";
          issuer = (ren.helpers.oidcProviderFor cluster "synapse").issuer;
          client_id = "synapse";
          client_secret_file = "/secrets/oidc-client-secret";
          token_endpoint_auth_method = "client_secret_basic";
          # kanidm signs id tokens with ES256, not the RS256 default.
          id_token_signed_response_alg = "ES256";
          pkce_method = "always";
          scope = "openid profile email";
          claims_imports = {
            skip_confirmation = true;
            localpart = {
              action = "require";
              template = "{{ user.preferred_username }}";
            };
            displayname = {
              action = "force";
              template = "{{ user.name }}";
            };
            email = {
              action = "force";
              template = "{{ user.email }}";
            };
          };
        }
      ];
    };
in
{
  ren.aspects.k8s-communication-matrix-mas.k8s-manifests =
    { cluster, idm-users, ... }:
    {
      applications.matrix-authentication-service.resources.configMaps."matrix-authentication-service-config".data."config.yaml" =
        builtins.toJSON (
          masConfig cluster (
            lib.sort lib.lessThan (
              map (u: u.name) (
                lib.filter (u: u.environment == cluster.environment && lib.elem adminGroup u.groups) idm-users
              )
            )
          )
        );
    };
}
