# qBittorrent route + auth: HTTPRoute on the default-gateway and Kanidm OIDC SecurityPolicy.
{ ren, ... }:
{
  ren.aspects.k8s-media-qbittorrent.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.qbittorrent.resources = {
        httpRoutes.qbittorrent.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "qbittorrent") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "qbittorrent"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "qbittorrent";
                  port = 8080;
                }
              ];
            }
          ];
        };

        securityPolicies."qbittorrent-oidc".spec = {
          targetRefs = [
            {
              group = "gateway.networking.k8s.io";
              kind = "HTTPRoute";
              name = "qbittorrent";
            }
          ];
          oidc = {
            provider = ren.helpers.oidcProviderFor cluster "qbittorrent";
            clientID = "qbittorrent";
            clientSecret.name = "qbittorrent-oidc-client-secret";
            scopes = [
              "email"
              "openid"
              "profile"
            ];
            # qBittorrent 5.x answers 404 to ANY request carrying an Authorization: Bearer header
            # (verified live 2026-06-11), and nothing in qbt consumes the forwarded token.
            forwardAccessToken = false;
          };
        };

        secrets.qbittorrent-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.qbittorrent-oidc-client-secret.sopsRef;
        };
      };
    };
}
