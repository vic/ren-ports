# prowlarr route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-prowlarr.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.prowlarr.resources = {
        httpRoutes.prowlarr.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "prowlarr") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "prowlarr"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "prowlarr";
                  port = 9696;
                }
              ];
              # Interactive search can run several minutes; 600s route timeout. The default-gateway
              # ClientTrafficPolicy raises stream_idle_timeout to match (see envoy-gateway.nix).
              timeouts.request = "600s";
            }
          ];
        };

        securityPolicies."prowlarr-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "prowlarr";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "prowlarr";
            clientID = "prowlarr";
            clientSecret.name = "prowlarr-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.prowlarr-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.prowlarr-oidc-client-secret.sopsRef;
        };
      };
    };
}
