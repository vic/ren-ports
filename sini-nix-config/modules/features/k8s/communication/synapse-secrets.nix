# synapse age secrets, composed secrets.yaml and the Secrets mounting them.
{ ... }:
let
  secretsTemplate = ''
    macaroon_secret_key: "%matrix-synapse-macaroon-secret-key%"
    form_secret: "%matrix-synapse-form-secret%"
    registration_shared_secret: "%matrix-synapse-registration-shared-secret%"
    database:
      name: psycopg2
      args:
        user: synapse
        password: "%matrix-pg-synapse-password%"
        dbname: synapse
        host: matrix-pg-rw.matrix.svc.cluster.local
        port: 5432
        sslmode: require
        cp_min: 5
        cp_max: 10
  '';
in
{
  ren.aspects.k8s-communication-matrix-synapse = {
    age-secrets =
      { environment, ... }:
      {
        imports = [
          ({ config, ... }: {
        age.secrets = {
          synapse-oidc-client-secret = {
            rekeyFile = environment.secretPath + "/oidc/synapse-oidc-client-secret.age";
            generator = {
              tags = [ "oidc" ];
              script = "rfc3986-secret";
            };
            sopsOutput = {
              file = "oidc";
              key = "synapse";
            };
          };
          matrix-synapse-macaroon-secret-key = {
            rekeyFile = environment.secretPath + "/matrix-synapse/macaroon-secret-key.age";
            generator.script = "rfc3986-secret";
          };
          matrix-synapse-form-secret = {
            rekeyFile = environment.secretPath + "/matrix-synapse/form-secret.age";
            generator.script = "rfc3986-secret";
          };
          matrix-synapse-registration-shared-secret = {
            rekeyFile = environment.secretPath + "/matrix-synapse/registration-shared-secret.age";
            generator.script = "rfc3986-secret";
            sopsOutput = {
              file = "matrix-synapse";
              key = "registration-shared-secret";
            };
          };
          matrix-synapse-signing-key = { # federation identity: back it up
            rekeyFile = environment.secretPath + "/matrix-synapse/signing-key.age";
            generator.script = "synapse-signing-key";
            sopsOutput = {
              file = "matrix-synapse";
              key = "signing-key";
            };
          };
          matrix-synapse-secrets-yaml = {
            rekeyFile = environment.secretPath + "/matrix-synapse/secrets-yaml.age";
            generator.script = "template-file";
            generator.dependencies = [
              config.age.secrets.matrix-synapse-macaroon-secret-key
              config.age.secrets.matrix-synapse-form-secret
              config.age.secrets.matrix-synapse-registration-shared-secret
              config.age.secrets.matrix-pg-synapse-password
            ];
            settings.template = secretsTemplate;
            sopsOutput = {
              file = "matrix-synapse";
              key = "secrets-yaml";
            };
          };
        };
          })
        ];
      };

    k8s-manifests =
      { config, ... }:
      {
        applications.synapse.resources.secrets = {
          matrix-synapse = {
            type = "Opaque";
            stringData = {
              "secrets.yaml" = config.age.secrets.matrix-synapse-secrets-yaml.sopsRef;
              "signing.key" = config.age.secrets.matrix-synapse-signing-key.sopsRef;
            };
          };
          # Also mounted by MAS (mas-deploy.nix), kanidm's client now.
          synapse-oidc-client-secret = {
            type = "Opaque";
            stringData.client-secret = config.age.secrets.synapse-oidc-client-secret.sopsRef;
          };
        };
      };
  };
}
