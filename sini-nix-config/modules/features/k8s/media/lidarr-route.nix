# lidarr route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-lidarr.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.lidarr.resources = {
        httpRoutes.lidarr.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "lidarr") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "lidarr"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "lidarr";
                  port = 8686;
                }
              ];
              # Interactive search (anime fans out to many title-variants x indexers) can run several minutes; 600s route timeout. The default-gateway
              # ClientTrafficPolicy raises stream_idle_timeout to match (see envoy-gateway.nix).
              timeouts.request = "600s";
            }
          ];
        };

        securityPolicies."lidarr-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "lidarr";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "lidarr";
            clientID = "lidarr";
            clientSecret.name = "lidarr-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.lidarr-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.lidarr-oidc-client-secret.sopsRef;
        };
      };
    };
}
