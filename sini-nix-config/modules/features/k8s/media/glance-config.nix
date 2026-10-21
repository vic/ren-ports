# Glance config: glance.yml as a ConfigMap mounted as a single file at /app/config/glance.yml
# via subPath (the image's default command already reads that path). Catppuccin Mocha; the monitor
# widget pings in-cluster short service names over HTTP and Jellyfin on its external HTTPS URL
# (no API keys).
{ ... }:
{
  ren.aspects.k8s-media-glance.k8s-manifests =
    { ... }:
    {
      applications.glance.helm.releases.glance.values = {
        configMaps.config.data."glance.yml" = ''
                theme:
                  # Catppuccin Mocha
                  background-color: 240 21 15
                  contrast-multiplier: 1.2
                  primary-color: 217 92 83
                  positive-color: 115 54 76
                  negative-color: 347 70 65

                pages:
                  - name: Home
                    columns:
                      - size: small
                        widgets:
                          - type: clock
                            hour-format: 12h
                          - type: calendar
                            first-day-of-week: monday
                      - size: full
                        widgets:
                          - type: rss
                            limit: 10
                            collapse-after: 3
                            cache: 12h
                            feeds:
                              - url: https://selfh.st/rss/
                                title: selfh.st

                  - name: Media
                    columns:
                      - size: full
                        widgets:
                          - type: monitor
                            cache: 1m
                            title: Media Services
                            sites:
                              - title: Sonarr
                                url: http://sonarr:8989/
                                icon: si:sonarr
                              - title: Radarr
                                url: http://radarr:7878/
                                icon: si:radarr
                              - title: Lidarr
                                url: http://lidarr:8686/
                                icon: si:lidarr
                              - title: Whisparr
                                url: http://whisparr:6969/
                                icon: si:w
                              - title: SABnzbd
                                url: http://sabnzbd:8080/
                                icon: si:sabnzbd
                              - title: Jellyfin
                                url: https://jellyfin.json64.dev/
                                icon: si:jellyfin
                      - size: small
                        widgets:
                          - type: bookmarks
                            groups:
                              - title: Media UIs
                                links:
                                  - title: Jellyfin
                                    url: https://jellyfin.json64.dev/
                                  - title: Sonarr
                                    url: https://sonarr.json64.dev/
                                  - title: Radarr
                                    url: https://radarr.json64.dev/
                                  - title: Lidarr
                                    url: https://lidarr.json64.dev/
                                  - title: Whisparr
                                    url: https://whisparr.json64.dev/
                                  - title: Prowlarr
                                    url: https://prowlarr.json64.dev/
                                  - title: Bazarr
                                    url: https://bazarr.json64.dev/
                                  - title: SABnzbd
                                    url: https://nzb.json64.dev/
                                  - title: qBittorrent
                                    url: https://torrent.json64.dev/
        '';

        persistence.config = {
          type = "configMap";
          identifier = "config";
          globalMounts = [
            {
              path = "/app/config/glance.yml";
              subPath = "glance.yml";
              readOnly = true;
            }
          ];
        };
      };
    };
}
