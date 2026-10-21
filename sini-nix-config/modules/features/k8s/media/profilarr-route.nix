# profilarr route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-profilarr.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.profilarr.resources = {
        httpRoutes.profilarr.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "profilarr") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "profilarr"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "profilarr";
                  port = 6868;
                }
              ];
              # No custom timeout: Profilarr does no slow interactive search. Envoy 15s route default applies.
            }
          ];
        };

        securityPolicies."profilarr-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "profilarr";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "profilarr";
            clientID = "profilarr";
            clientSecret.name = "profilarr-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.profilarr-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.profilarr-oidc-client-secret.sopsRef;
        };
      };
    };
}
