# prowlarr OIDC client secret (agenix generator, rekeyed into sops file `oidc`).
{ ... }:
{
  ren.aspects.k8s-media-prowlarr = {
    age-secrets =
      { environment, ... }:
      {
        age.secrets.prowlarr-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/prowlarr-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "prowlarr";
          };
        };
      };
  };
}
