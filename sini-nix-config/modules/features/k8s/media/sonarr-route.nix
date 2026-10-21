# sonarr route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-sonarr.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.sonarr.resources = {
        httpRoutes.sonarr.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "sonarr") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "sonarr"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "sonarr";
                  port = 8989;
                }
              ];
              # Interactive search can run several minutes; 600s route timeout. The default-gateway
              # ClientTrafficPolicy raises stream_idle_timeout to match (see envoy-gateway.nix).
              timeouts.request = "600s";
            }
          ];
        };

        securityPolicies."sonarr-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "sonarr";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "sonarr";
            clientID = "sonarr";
            clientSecret.name = "sonarr-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.sonarr-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.sonarr-oidc-client-secret.sopsRef;
        };
      };
    };
}
