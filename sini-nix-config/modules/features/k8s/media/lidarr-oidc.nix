# lidarr OIDC client secret (agenix generator, rekeyed into sops file `oidc`).
{ ... }:
{
  ren.aspects.k8s-media-lidarr = {
    age-secrets =
      { environment, ... }:
      {
        age.secrets.lidarr-oidc-client-secret = {
          rekeyFile = environment.secretPath + "/oidc/lidarr-oidc-client-secret.age";
          generator = {
            tags = [ "oidc" ];
            script = "rfc3986-secret";
          };
          sopsOutput = {
            file = "oidc";
            key = "lidarr";
          };
        };
      };
  };
}
