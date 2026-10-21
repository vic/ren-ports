# sonarr OIDC client secret (agenix generator, rekeyed into sops file `oidc`).
{ ... }:
{
  ren.aspects.k8s-media-sonarr = {
    age-secrets =
      { environment, ... }:
      {
        age.secrets.sonarr-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/sonarr-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "sonarr";
          };
        };
      };
  };
}
