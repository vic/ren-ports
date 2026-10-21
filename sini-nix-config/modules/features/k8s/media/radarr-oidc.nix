# radarr OIDC client secret (agenix generator, rekeyed into sops file `oidc`).
{ ... }:
{
  ren.aspects.k8s-media-radarr = {
    age-secrets =
      { environment, ... }:
      {
        age.secrets.radarr-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/radarr-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "radarr";
          };
        };
      };
  };
}
