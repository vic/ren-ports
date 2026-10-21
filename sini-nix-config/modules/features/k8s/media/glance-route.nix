# Glance route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-glance.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.glance.resources = {
        httpRoutes.glance.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "glance") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "glance"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "glance";
                  port = 8080;
                }
              ];
            }
          ];
        };

        securityPolicies."glance-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "glance";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "glance";
            clientID = "glance";
            clientSecret.name = "glance-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.glance-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.glance-oidc-client-secret.sopsRef;
        };
      };
    };
}
