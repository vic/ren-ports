# tdarr OIDC client secret (agenix generator, rekeyed into sops file `oidc`).
{ ... }:
{
  ren.aspects.k8s-media-tdarr = {
    age-secrets =
      { environment, ... }:
      {
        age.secrets.tdarr-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/tdarr-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "tdarr";
          };
        };
      };
  };
}
