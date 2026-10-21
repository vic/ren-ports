# Tdarr route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-tdarr.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.tdarr.resources = {
        httpRoutes.tdarr.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "tdarr") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "tdarr"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "tdarr";
                  port = 8265;
                }
              ];
            }
          ];
        };

        securityPolicies."tdarr-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "tdarr";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "tdarr";
            clientID = "tdarr";
            clientSecret.name = "tdarr-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            # If tdarr's UI is later found to reject a forwarded Bearer token, flip this to false
            # (the arrs forward; the UI is OIDC-gated at the gateway either way).
            forwardAccessToken = true;
          };
        };

        secrets.tdarr-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.tdarr-oidc-client-secret.sopsRef;
        };
      };
    };
}
