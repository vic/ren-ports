# Shoko route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-shoko.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.shoko.resources = {
        httpRoutes.shoko.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "shoko") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "shoko"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "shoko";
                  port = 8111;
                }
              ];
            }
          ];
        };

        securityPolicies."shoko-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "shoko";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "shoko";
            clientID = "shoko";
            clientSecret.name = "shoko-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.shoko-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.shoko-oidc-client-secret.sopsRef;
        };
      };
    };
}
