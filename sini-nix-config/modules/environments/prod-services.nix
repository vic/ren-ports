# Prod environment instance: service domains.
{ ... }:
{
  ren.environment.prod.services = {
    argocd.domain = "argocd.zeroday.run";
    hubble-ui.domain = "hubble.zeroday.run";
    longhorn.domain = "longhorn.zeroday.run";
    attic.domain = "attic.json64.dev";
    forgejo.domain = "git.json64.dev";
    garage-s3.domain = "s3.json64.dev";
    garage-ui.domain = "garage.json64.dev";
    grafana.domain = "grafana.json64.dev";
    headscale.domain = "hs.json64.dev";
    homepage.domain = "homepage.json64.dev";
    # k8s media utility dashboard (gethomepage), distinct from the uplink homepage.
    dash.domain = "dash.json64.dev";
    jellyfin.domain = "jellyfin.json64.dev";
    kanidm.domain = "idm.json64.dev";
    loki.domain = "loki.json64.dev";
    minio.domain = "minio.json64.dev";
    minio-console.domain = "minio-console.json64.dev";
    oauth2-proxy.domain = "oauth2-proxy.json64.dev";
    open-webui.domain = "open-webui.json64.dev";
    prometheus.domain = "prometheus.json64.dev";
    # qBittorrent routes on torrent.* (not the default qbittorrent.*).
    qbittorrent.domain = "torrent.json64.dev";
    registry.domain = "registry.json64.dev";
    # SABnzbd routes on nzb.* (not the default sabnzbd.*).
    sabnzbd.domain = "nzb.json64.dev";
    vault.domain = "vault.json64.dev";
    den-docs-mirror.domain = "den.json64.dev";
    gen-status.domain = "gen-status.json64.dev";
    # Companion homeserver (tuwunel).
    tuwunel.domain = "matrix.gen.wtf";
  };
}
