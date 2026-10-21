# Shared *arr API keys for the media stack: one stable 32-char hex key per app via agenix
# (`hex-secret` generator), surfaced in a single k8s Secret `media-arr-api-keys`.
# Apps reference their key with env.<APP>__AUTH__APIKEY.valueFrom.secretKeyRef (key = <app>).
{ lib, ... }:
{
  ren.aspects.k8s-media-api-keys = {
    # One generated key per app, rekeyed under the shared `media-arr-api-keys` sops file (key = <app>).
    age-secrets =
      { environment, ... }:
      {
        age.secrets = lib.listToAttrs (
          map
            (
              app:
              lib.nameValuePair "media-arr-api-keys-${app}" {
                rekeyFile = environment.secretPath + "/media-arr-api-keys/${app}.age";
                generator.script = "hex-secret";
                sopsOutput = {
                  file = "media-arr-api-keys";
                  key = app;
                };
              }
            )
            [
              "prowlarr"
              "sonarr"
              "radarr"
              "lidarr"
              "whisparr"
              "bazarr"
              "sabnzbd"
            ]
        );
      };

    k8s-manifests =
      { config, ... }:
      {
        applications.media-secrets = {
          namespace = "media";
          # Shared secrets before the app fleet (wave 0) consumes them.
          annotations."argocd.argoproj.io/sync-wave" = "-1";
          resources.secrets."media-arr-api-keys" = {
            type = "Opaque";
            # One stringData entry per app; each a sops ref resolved at render time.
            stringData = lib.listToAttrs (
              map (app: lib.nameValuePair app config.age.secrets."media-arr-api-keys-${app}".sopsRef) [
                "prowlarr"
                "sonarr"
                "radarr"
                "lidarr"
                "whisparr"
                "bazarr"
                "sabnzbd"
              ]
            );
          };
        };
      };
  };
}
