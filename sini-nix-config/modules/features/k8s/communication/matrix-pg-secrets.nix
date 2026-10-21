# matrix-pg role passwords: age secrets and their basic-auth Secrets.
_: {
  ren.aspects.k8s-communication-matrix-pg = {
    # Generated role passwords, rekeyed into the cluster sops store. The .age
    # files are created by `agenix generate`. template-file substitutes the
    # password into a standalone URL so the resulting sops value is a single
    # ref that encrypts cleanly.
    age-secrets =
      { environment, ... }:
      {
        age.secrets = {
          matrix-pg-synapse-password = {
            rekeyFile = environment.secretPath + "/matrix-pg/synapse-password.age";
            generator.script = "rfc3986-secret";
            sopsOutput = {
              file = "matrix-pg";
              key = "synapse";
            };
          };
          matrix-pg-mas-password = {
            rekeyFile = environment.secretPath + "/matrix-pg/mas-password.age";
            generator.script = "rfc3986-secret";
            sopsOutput = {
              file = "matrix-pg";
              key = "mas";
            };
          };
        };
      };

    k8s-manifests =
      { config, ... }:
      {
        applications.matrix-pg.resources = {
        # basic-auth secrets for the roles; the nixidy objectTransform rewrites
        # Secret to SopsSecret, the password is a sops ref resolved at render.
        secrets = {
          matrix-pg-synapse-password = {
            type = "kubernetes.io/basic-auth";
            stringData = {
              username = "synapse";
              password = config.age.secrets.matrix-pg-synapse-password.sopsRef;
            };
          };
          matrix-pg-mas-password = {
            type = "kubernetes.io/basic-auth";
            stringData = {
              username = "mas";
              password = config.age.secrets.matrix-pg-mas-password.sopsRef;
            };
          };
        };
        };
      };
  };
}
