# RomM metadata-provider env: Hasheous keyless; IGDB, SteamGridDB, RetroAchievements from media-romm-metadata.
{ ... }:
{
  ren.aspects.k8s-media-romm.k8s-manifests =
    { ... }:
    {
      applications.romm.helm.releases.romm.values.controllers.main.containers.main.env = {
                  # Hasheous is keyless; the other three take creds from media-romm-metadata.
                  HASHEOUS_API_ENABLED = "true";
                  IGDB_CLIENT_ID.valueFrom.secretKeyRef = {
                    name = "media-romm-metadata";
                    key = "igdb-client-id";
                  };
                  IGDB_CLIENT_SECRET.valueFrom.secretKeyRef = {
                    name = "media-romm-metadata";
                    key = "igdb-client-secret";
                  };
                  STEAMGRIDDB_API_KEY.valueFrom.secretKeyRef = {
                    name = "media-romm-metadata";
                    key = "steamgriddb-api-key";
                  };
                  RETROACHIEVEMENTS_API_KEY.valueFrom.secretKeyRef = {
                    name = "media-romm-metadata";
                    key = "retroachievements-api-key";
                  };
      };
    };
}
