# Komga route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-komga.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.komga.resources = {
        httpRoutes.komga.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "komga") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "komga"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "komga";
                  port = 25600;
                }
              ];
            }
          ];
        };

        securityPolicies."komga-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "komga";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "komga";
            clientID = "komga";
            clientSecret.name = "komga-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.komga-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.komga-oidc-client-secret.sopsRef;
        };
      };
    };
}
