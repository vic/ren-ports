# whisparr route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-whisparr.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.whisparr.resources = {
        httpRoutes.whisparr.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "whisparr") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "whisparr"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "whisparr";
                  port = 6969;
                }
              ];
              # Interactive search can run several minutes; 600s route timeout. The default-gateway
              # ClientTrafficPolicy raises stream_idle_timeout to match (see envoy-gateway.nix).
              timeouts.request = "600s";
            }
          ];
        };

        securityPolicies."whisparr-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "whisparr";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "whisparr";
            clientID = "whisparr";
            clientSecret.name = "whisparr-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.whisparr-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.whisparr-oidc-client-secret.sopsRef;
        };
      };
    };
}
