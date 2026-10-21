# SABnzbd route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-sabnzbd.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.sabnzbd.resources = {
        httpRoutes.sabnzbd.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "sabnzbd") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "sabnzbd"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "sabnzbd";
                  port = 8080;
                }
              ];
            }
          ];
        };

        securityPolicies."sabnzbd-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "sabnzbd";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "sabnzbd";
            clientID = "sabnzbd";
            clientSecret.name = "sabnzbd-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            forwardAccessToken = true;
          };
        };

        secrets.sabnzbd-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.sabnzbd-oidc-client-secret.sopsRef;
        };
      };
    };
}
