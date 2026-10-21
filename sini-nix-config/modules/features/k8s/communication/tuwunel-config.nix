# tuwunel config file, data PVC and OIDC client secret.
{ ren, ... }:
let
  tomlConfig = host: ''
    [global]
    server_name = "gen.wtf"
    address = ["0.0.0.0"]
    port = 8008
    database_path = "/data/db"
    allow_registration = false
    allow_federation = true
    trusted_servers = ["matrix.org"]
    max_request_size = 52428800

    [global.well_known]
    client = "https://${host}"
    server = "${host}:443"

    [[global.identity_provider]]
    brand = "kanidm"
    name = "json64 (kanidm)"
    client_id = "tuwunel"
    client_secret_file = "/secrets/oidc-client-secret"
    issuer_url = "https://idm.json64.dev/oauth2/openid/tuwunel"
    callback_url = "https://${host}/_matrix/client/unstable/login/sso/callback/tuwunel"
    scope = ["openid", "profile", "email"]
    userid_claims = ["preferred_username"]
    unique_id_fallbacks = false
    registration = true
    default = true
  '';
in
{
  ren.aspects.k8s-communication-matrix-tuwunel.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.tuwunel.helm.releases.tuwunel.values = {
      service.main = {
        controller = "main";
        ports.http.port = 8008;
      };
      persistence = {
        config = {
          type = "configMap";
          name = "tuwunel-config";
          globalMounts = [ { path = "/config"; } ];
        };
        oidc = {
          type = "secret";
          name = "tuwunel-oidc-client-secret";
          globalMounts = [
            {
              path = "/secrets/oidc-client-secret";
              subPath = "client-secret";
              readOnly = true;
            }
          ];
        };
        data = {
          type = "persistentVolumeClaim";
          existingClaim = "tuwunel-data";
          globalMounts = [ { path = "/data"; } ];
        };
      };
      };

      applications.tuwunel.resources = {
        configMaps.tuwunel-config.data."tuwunel.toml" = tomlConfig (
          ren.helpers.clusterDomainFor cluster "tuwunel"
        );

        persistentVolumeClaims.tuwunel-data.spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "longhorn";
          resources.requests.storage = "20Gi";
        };

        secrets.tuwunel-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.tuwunel-oidc-client-secret.sopsRef;
        };
      };
    };
}
