# radarr route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-radarr.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.radarr.resources = {
        httpRoutes.radarr.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "radarr") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "radarr"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "radarr";
                  port = 7878;
                }
              ];
              # Interactive search can run several minutes; 600s route timeout. The default-gateway
              # ClientTrafficPolicy raises stream_idle_timeout to match (see envoy-gateway.nix).
              timeouts.request = "600s";
            }
          ];
        };

        securityPolicies."radarr-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "radarr";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "radarr";
            clientID = "radarr";
            clientSecret.name = "radarr-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.radarr-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.radarr-oidc-client-secret.sopsRef;
        };
      };
    };
}
