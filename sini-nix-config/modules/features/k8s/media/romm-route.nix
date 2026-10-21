# RomM route + secrets. No SecurityPolicy: native OIDC (romm-oidc-client-secret is read by OIDC_CLIENT_SECRET env).
{ ren, ... }:
{
  ren.aspects.k8s-media-romm.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.romm.resources = {
        httpRoutes.romm.spec = {
          hostnames = [ (ren.helpers.clusterDomainFor cluster "romm") ];
          parentRefs = [
            {
              name = "default-gateway";
              namespace = "gateways";
              sectionName = "${ren.helpers.domainForResource cluster "romm"}-https";
            }
          ];
          rules = [
            {
              backendRefs = [
                {
                  name = "romm";
                  port = 8080;
                }
              ];
            }
          ];
        };

        secrets.romm-oidc-client-secret = {
          type = "Opaque";
          stringData.client-secret = config.age.secrets.romm-oidc-client-secret.sopsRef;
        };

        secrets.media-romm = {
          type = "Opaque";
          stringData = {
            auth-secret-key = config.age.secrets.media-romm-auth-secret-key.sopsRef;
            redis-password = config.age.secrets.media-romm-redis-password.sopsRef;
          };
        };

        # IGDB needs id + secret; SteamGridDB and RetroAchievements one key each.
        secrets.media-romm-metadata = {
          type = "Opaque";
          stringData = {
            igdb-client-id = config.age.secrets.media-romm-metadata-igdb-client-id.sopsRef;
            igdb-client-secret = config.age.secrets.media-romm-metadata-igdb-client-secret.sopsRef;
            steamgriddb-api-key = config.age.secrets.media-romm-metadata-steamgriddb-api-key.sopsRef;
            retroachievements-api-key =
              config.age.secrets.media-romm-metadata-retroachievements-api-key.sopsRef;
          };
        };
      };
    };
}
