# whisparr OIDC client secret (agenix generator, rekeyed into sops file `oidc`).
{ ... }:
{
  ren.aspects.k8s-media-whisparr = {
    age-secrets =
      { environment, ... }:
      {
        age.secrets.whisparr-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/whisparr-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "whisparr";
          };
        };
      };
  };
}
