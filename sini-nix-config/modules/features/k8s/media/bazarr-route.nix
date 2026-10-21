# Bazarr route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-bazarr.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.bazarr.resources = {
        httpRoutes.bazarr.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "bazarr") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "bazarr"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "bazarr";
                  port = 6767;
                }
              ];
              # Interactive search can run several minutes; 600s route timeout. The default-gateway
              # ClientTrafficPolicy raises stream_idle_timeout to match (see envoy-gateway.nix).
              timeouts.request = "600s";
            }
          ];
        };

        securityPolicies."bazarr-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "bazarr";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "bazarr";
            clientID = "bazarr";
            clientSecret.name = "bazarr-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.bazarr-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.bazarr-oidc-client-secret.sopsRef;
        };
      };
    };
}
