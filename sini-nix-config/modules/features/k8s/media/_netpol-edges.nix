# Media network-policy edge graph (single source of truth). Edges owned by an app file are EXCLUDED:
# unpackerr->*arr, profilarr->sonarr/radarr, *->qbittorrent ingress, media-pg->kube-apiserver.
lib:
let
  arrs = [
    "sonarr"
    "radarr"
    "lidarr"
    "whisparr"
  ];
  downloaders = [
    "sabnzbd"
    "qbittorrent"
  ];
in
{
  inherit arrs;

  # Service web/API ports.
  ports = {
    prowlarr = 9696;
    sonarr = 8989;
    radarr = 7878;
    lidarr = 8686;
    whisparr = 6969;
    flaresolverr = 8191;
    sabnzbd = 8080;
    qbittorrent = 8080;
  };

  # Dashboards (glance, dash): pre-declared ingress sources on the API ports so their tasks need no edits.
  # Pods carry app.kubernetes.io/name = dash (k8s dashboard renamed from "homepage").
  dashboards = [
    "glance"
    "dash"
  ];

  # { from; to; }: every directed in-namespace TCP edge to the target's port.
  edges =
    # *arr <-> prowlarr (indexer sync, both directions)
    map (a: {
      from = a;
      to = "prowlarr";
    }) arrs
    ++ map (a: {
      from = "prowlarr";
      to = a;
    }) arrs
    # prowlarr -> flaresolverr (cloudflare challenge solving)
    ++ [
      {
        from = "prowlarr";
        to = "flaresolverr";
      }
    ]
    # *arr -> downloaders (download-client registration + queue management)
    ++ lib.concatMap (
      a:
      map (d: {
        from = a;
        to = d;
      }) downloaders
    ) arrs
    # bazarr -> sonarr/radarr (subtitle sync reads series/movie metadata)
    ++ [
      {
        from = "bazarr";
        to = "sonarr";
      }
      {
        from = "bazarr";
        to = "radarr";
      }
    ];
}
