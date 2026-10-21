# Dash config (settings + services): raw ConfigMap "dash-config" (not the chart's `configMaps`) so
# the data bypasses app-template's Helm `tpl` pass, which would evaluate homepage's
# `{{HOMEPAGE_VAR_*}}` tokens as Helm template calls and fail. Rest of the files: dash-widgets.nix.
{ ... }:
{
  ren.aspects.k8s-media-dash.k8s-manifests =
    { ... }:
    {
      applications.dash.resources.configMaps.dash-config = {
        metadata.namespace = "media";
        data = {
      "settings.yaml" = ''
        title: Media Dashboard
        theme: dark
        color: slate
        headerStyle: clean
        layout:
          Media:
            style: row
            columns: 4
          Downloaders:
            style: row
            columns: 2
      '';

      # Static service list with widgets keyed by {{HOMEPAGE_VAR_*_KEY}} env.
      "services.yaml" = ''
        - Media:
            - Sonarr:
                href: https://sonarr.json64.dev/
                icon: sonarr.png
                widget:
                  type: sonarr
                  url: http://sonarr:8989
                  key: "{{HOMEPAGE_VAR_SONARR_KEY}}"
            - Radarr:
                href: https://radarr.json64.dev/
                icon: radarr.png
                widget:
                  type: radarr
                  url: http://radarr:7878
                  key: "{{HOMEPAGE_VAR_RADARR_KEY}}"
            - Lidarr:
                href: https://lidarr.json64.dev/
                icon: lidarr.png
                widget:
                  type: lidarr
                  url: http://lidarr:8686
                  key: "{{HOMEPAGE_VAR_LIDARR_KEY}}"
            - Prowlarr:
                href: https://prowlarr.json64.dev/
                icon: prowlarr.png
                # No widget: prowlarr API is admin-gated; surfaced as bookmark only.
        - Downloaders:
            - SABnzbd:
                href: https://nzb.json64.dev/
                icon: sabnzbd.png
                widget:
                  type: sabnzbd
                  url: http://sabnzbd:8080
                  key: "{{HOMEPAGE_VAR_SABNZBD_KEY}}"
            - qBittorrent:
                href: https://torrent.json64.dev/
                icon: qbittorrent.png
                # No widget: the qbt WebUI is OIDC/loopback-locked; homepage cannot
                # authenticate to it. Torrent status is visible via the *arrs.
        - Watch:
            - Jellyfin:
                href: https://jellyfin.json64.dev/
                icon: jellyfin.png
      '';
        };
      };
    };
}
