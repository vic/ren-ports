# searxng secrets: the settings secret_key and the gateway's OIDC client secret.
_: {
  ren.aspects.k8s-ai-searxng.age-secrets =
    { environment, ... }:
    {
      searxng-secret-key = {
        rekeyFile = environment.secretPath + "/searxng/secret-key.age";
        generator.script = "hex";
        sopsOutput = {
          file = "searxng";
          key = "secret-key";
        };
      };
      # Shared with the kanidm client (services/security/kanidm.nix): same
      # rekeyFile, so one generated value backs both sides.
      searxng-oidc-client-secret = {
        rekeyFile = environment.secretPath + "/oidc/searxng-oidc-client-secret.age";
        generator = {
          tags = [ "oidc" ];
          script = "rfc3986-secret";
        };
        sopsOutput = {
          file = "oidc";
          key = "searxng";
        };
      };
    };
}
