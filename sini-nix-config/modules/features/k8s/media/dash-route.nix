# Dash route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-dash.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.dash.resources = {
        httpRoutes.dash.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "dash") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "dash"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "dash";
                  port = 3000;
                }
              ];
            }
          ];
        };

        securityPolicies."dash-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "dash";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "dash";
            clientID = "dash";
            clientSecret.name = "dash-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.dash-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.dash-oidc-client-secret.sopsRef;
        };
      };
    };
}
