# Dash config (widgets, bookmarks, kubernetes): merges into the raw ConfigMap "dash-config" (dash-config.nix).
{ ... }:
{
  ren.aspects.k8s-media-dash.k8s-manifests =
    { ... }:
    {
      applications.dash.resources.configMaps.dash-config.data = {
        "widgets.yaml" = ''
          - resources:
              backend: kubernetes
              expanded: true
              cpu: true
              memory: true
          - kubernetes:
              cluster:
                show: true
                cpu: true
                memory: true
                showLabel: true
              nodes:
                show: true
                cpu: true
                memory: true
          - search:
              provider: duckduckgo
              target: _blank
        '';

        "bookmarks.yaml" = ''
          - Media:
              - Jellyfin:
                  - abbr: JF
                    href: https://jellyfin.json64.dev/
              - Bazarr:
                  - abbr: BZ
                    href: https://bazarr.json64.dev/
              - Whisparr:
                  - abbr: WH
                    href: https://whisparr.json64.dev/
        '';

        "kubernetes.yaml" = ''
          mode: cluster
        '';
      };
    };
}
