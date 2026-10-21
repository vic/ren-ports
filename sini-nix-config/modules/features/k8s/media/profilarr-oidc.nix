# profilarr OIDC client secret (agenix generator, rekeyed into sops file `oidc`).
{ ... }:
{
  ren.aspects.k8s-media-profilarr = {
    age-secrets =
      { environment, ... }:
      {
        age.secrets.profilarr-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/profilarr-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "profilarr";
          };
        };
      };
  };
}
