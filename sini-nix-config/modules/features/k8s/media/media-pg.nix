# media-pg roles: login role per postgres-capable app (the *arrs, bazarr, romm). Password is an agenix-generated
# secret (rekeyed into sops `media-pg`) surfaced as a k8s basic-auth Secret (-> SopsSecret). The Cluster itself
# is in media-pg-cluster.nix; PodMonitor + apiserver CNP in media-pg-monitor.nix. Role/db lists: _media-pg-lib.nix.
# Apps connect via CNPG services media-pg-rw (primary) / media-pg-ro (replicas).
{ lib, ... }:
{
  ren.aspects.k8s-media-pg = {
    # One generated password per role. The .age files are created by `agenix generate` after this lands.
    age-secrets =
      { environment, ... }:
      {
        age.secrets = lib.listToAttrs (
          map (
            app:
            lib.nameValuePair ((import ./_media-pg-lib.nix lib).passwordSecretName app) {
              rekeyFile = environment.secretPath + "/media-pg/${app}-password.age";
              generator.script = "rfc3986-secret";
              sopsOutput = {
                file = "media-pg";
                key = app;
              };
            }
          ) (import ./_media-pg-lib.nix lib).roleApps
        );
      };

    k8s-manifests =
      # `config` is the nixidy module config: the cluster-age aspect imports the agenix-rekey-to-sops bridge,
      # so config.age.secrets (and .sopsRef) are available.
      { config, ... }:
      {
        # Per-role password Secrets (basic-auth). nixidy objectTransform rewrites Secret -> SopsSecret.
        applications.media-pg.resources.secrets = lib.listToAttrs (
          map (
            app:
            lib.nameValuePair ((import ./_media-pg-lib.nix lib).passwordSecretName app) {
              type = "kubernetes.io/basic-auth";
              stringData = {
                username = app;
                password = config.age.secrets.${(import ./_media-pg-lib.nix lib).passwordSecretName app}.sopsRef;
              };
            }
          ) (import ./_media-pg-lib.nix lib).roleApps
        );
      };
  };
}
