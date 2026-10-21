# mas: the Matrix Authentication Service for json64.dev, served at
# matrix-auth.json64.dev. Synapse delegates all authentication to it, which is
# what lets OAuth 2.0 clients (Element X) log in; legacy clients use its
# compatibility layer for /login, /logout and /refresh.
#
# Login is kanidm, as MAS's only upstream provider. It reuses kanidm's `synapse`
# client: the same issuer keeps every user's subject, so the links syn2mas
# imported from Synapse stay valid. Passwords are off; the bcrypt scheme exists
# only because syn2mas requires one to import into.
#
# Config is split like Synapse's: the non-secret config.yaml (mas-config.nix)
# and secrets.yaml (a template-file age secret holding the database URI, which
# has no *_file option). The other secrets are mounted as files.
#
# Server admins are kanidm's `admins` group, routed here as `idm-users`: MAS
# lets them request Synapse's admin scope, which Ketesa (matrix-admin) asks for.
# The syn2mas import (docs/runbooks/matrix-mas-migration.md) is done; its Job
# stays declared, disabled, in mas-deploy.nix. Routes in mas-route.nix, CNPs in
# mas-net.nix.
{ ren, ... }:
let
  secretsTemplate = ''
    database:
      uri: "postgresql://mas:%matrix-pg-mas-password%@matrix-pg-rw.matrix.svc.cluster.local:5432/mas?sslmode=require"
  '';
in
{
  ren.aspects.k8s-communication-matrix-mas = {
    service-domains = [ "matrix-auth" ];
    served-domains = { cluster, ... }: ren.helpers.clusterServedDomains cluster [ "matrix-auth" ];

    age-secrets =
      { environment, ... }:
      {
        imports = [
          ({ config, ... }: {
        age.secrets = {
          # Encrypts cookies and database fields. Never change it once MAS has run.
          matrix-mas-encryption-key = {
            rekeyFile = environment.secretPath + "/matrix-mas/encryption-key.age";
            generator.script = "hex";
            settings.length = 32;
            sopsOutput = {
              file = "matrix-mas";
              key = "encryption-key";
            };
          };
          matrix-mas-signing-key = {
            rekeyFile = environment.secretPath + "/matrix-mas/signing-key.age";
            generator.script = "rsa-private-key";
            sopsOutput = {
              file = "matrix-mas";
              key = "signing-key";
            };
          };
          # Authenticates MAS and Synapse to each other. Admin-equivalent.
          matrix-mas-shared-secret = {
            rekeyFile = environment.secretPath + "/matrix-mas/shared-secret.age";
            generator.script = "rfc3986-secret";
            sopsOutput = {
              file = "matrix-mas";
              key = "shared-secret";
            };
          };
          matrix-mas-secrets-yaml = {
            rekeyFile = environment.secretPath + "/matrix-mas/secrets-yaml.age";
            generator.script = "template-file";
            generator.dependencies = [ config.age.secrets.matrix-pg-mas-password ];
            settings.template = secretsTemplate;
            sopsOutput = {
              file = "matrix-mas";
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
        applications.matrix-authentication-service.resources.secrets.matrix-mas = {
          type = "Opaque";
          stringData = {
            "secrets.yaml" = config.age.secrets.matrix-mas-secrets-yaml.sopsRef;
            "encryption-key" = config.age.secrets.matrix-mas-encryption-key.sopsRef;
            "signing.key" = config.age.secrets.matrix-mas-signing-key.sopsRef;
            "shared-secret" = config.age.secrets.matrix-mas-shared-secret.sopsRef;
          };
        };
      };
  };
}
