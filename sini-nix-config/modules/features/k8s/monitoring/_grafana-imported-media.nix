# Pinned upstream dashboards (media exporters). Imported by grafana-dashboards.nix.
{
    # Media exporters. The *arr/sabnzbd metrics come from exportarr
    # (app-prefixed series, e.g. sonarr_*, prowlarr_*); these community
    # dashboards are authored against exportarr's schema and filter by
    # the datasource/instance template vars (no hardcoded job), so they
    # match our job="media/<app>" series.
    media-sonarr = {
      title = "Sonarr";
      folder = "Media";
      url = "https://grafana.com/api/dashboards/12530/revisions/2/download";
      sha256 = "0nqnl7vyg0nlskgxskhkyfyn2c0izf2wq5350sg4x8sp1zv1q429";
      fixDatasource = true;
      excludeColonInstances = true;
    };
    media-radarr = {
      title = "Radarr";
      folder = "Media";
      url = "https://grafana.com/api/dashboards/12896/revisions/1/download";
      sha256 = "1fqpwp544sc3m0gvnn9cvgiampkwilpp5vizhix2182c120waqih";
      fixDatasource = true;
      excludeColonInstances = true;
    };
    # exportarr's own multi-app "Media Dashboard" — the only
    # exportarr-schema dashboard covering Lidarr/Prowlarr/SABnzbd (no
    # standalone grafana.com ids exist for those); per-app instance
    # template vars, no hardcoded job filters.
    media-exportarr = {
      title = "Media (exportarr)";
      folder = "Media";
      url = "https://raw.githubusercontent.com/onedr0p/exportarr/88b9d3d0916ca701b89a2bdefe8b1d5b45294111/examples/grafana/dashboard2.json";
      sha256 = "158bvaf8djk9rda9vswpqkigkpawbw3arpg2vraaqgdblqqdlhs1";
      fixDatasource = true;
      excludeColonInstances = true;
    };
    # qBittorrent via the esanchezm exporter — this dashboard ships in
    # that exporter's repo and matches our qbittorrent_* schema
    # (qbittorrent_alltime_dl_total, _connected, _dht_nodes, …). The
    # common grafana.com id 15116 targets a DIFFERENT exporter
    # (qbittorrent_global_*/_torrent_*) and would not bind.
    media-qbittorrent = {
      title = "qBittorrent";
      folder = "Media";
      url = "https://raw.githubusercontent.com/esanchezm/prometheus-qbittorrent-exporter/fac38ac30d29e3bac4d3044c2011f523fc7c04c6/grafana/dashboard.json";
      sha256 = "0l7z8dfnm4crxlczd5a6cdgnz9jy91vmxq25x78rjkskky02an8h";
      fixDatasource = true;
      excludeColonInstances = true;
    };
    # Unpackerr — golift's own dashboard, keyed on unpackerr_* with an
    # instance template var our series populate.
    media-unpackerr = {
      title = "Unpackerr";
      folder = "Media";
      url = "https://grafana.com/api/dashboards/18817/revisions/1/download";
      sha256 = "1p7xlfm7kbydymh7gxl60bm7bj3cphjbf69hnqqsbkm0npj99jgw";
      fixDatasource = true;
      excludeColonInstances = true;
    };
    # Tdarr via the homeylab/tdarr-exporter v3 sidecar — the exporter's
    # own v3 dashboard (examples/dashboard.json pinned at the v3.0.0 tag;
    # archive/ holds the retired v1/v2 ones). Keyed on the v3 tdarr_*
    # schema: tdarr_size_diff_bytes (space saved), files/transcode counts,
    # per-library tdarr_library_transcodes_completed_total joined to
    # tdarr_library_info for the name, node/worker status
    # (tdarr_node_worker_status), and tdarr_server_uptime_seconds. No
    # excludeColonInstances: this dashboard's instance variable is
    # `tdarr_instance` (the exporter-set server hostname — here `localhost`,
    # never a colon-form pod-IP), not the prometheus `instance` label our
    # PodMonitor relabels, so the pod-IP churn that option fixes can't arise.
    media-tdarr = {
      title = "Tdarr";
      folder = "Media";
      url = "https://raw.githubusercontent.com/homeylab/tdarr-exporter/28de93aaea020744ce246f4eb33ef9e830a52419/examples/dashboard.json";
      sha256 = "03h41n18csh0jjvxlxqbk9ssf8gaxk4k210wq6nla32zzrlc2n5w";
      fixDatasource = true;
    };
}
