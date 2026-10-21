# Build-time dashboard fetch+transform (no runtime downloads): title normalized,
# grafana.com `__inputs` datasource placeholders bound to the Prometheus datasource.
# Pinned, imported by grafana-dashboards.nix (not auto-imported).
{ lib, pkgs }:
  {
    name,
    title,
    url,
    sha256,
    fixDatasource ? false,
    # Filter colon-form (pod-IP:port) values out of any `*instance*`
    # template variable. Our media exporters relabel `instance` to a
    # stable app-name, but deleted pre-relabel pod-IP series linger in
    # the prometheus index until head compaction, so `label_values`
    # still offers them → duplicate repeated panels. Drop them at the
    # variable. Only for dashboards whose instance IS app-name (NOT
    # node-exporter dashboards where instance is legitimately host:port).
    excludeColonInstances ? false,
  }:
  builtins.readFile (
    pkgs.runCommand "grafana-dashboard-${name}"
      {
        src = pkgs.fetchurl { inherit url sha256; };
        nativeBuildInputs = [
          pkgs.jq
          pkgs.gnused
        ];
      }
      ''
        ${
          if fixDatasource then
            # Bind the grafana.com datasource input to ours. The
            # legacy line sed rewrites bare-string datasource refs
            # ("datasource": "$datasource" | "''${DS_X}" | null) to
            # the "Prometheus" name. Newer dashboards instead use the
            # object form ({"type":"prometheus","uid":"''${DS_X}"})
            # split across lines, which that sed misses, so a first
            # pass substitutes any ''${DS_*} input placeholder with
            # the pinned datasource uid (a no-op for dashboards that
            # use a different placeholder, which the line sed then
            # catches by the string rule).
            ''sed -E 's/\$\{DS_[A-Z0-9_]+\}/prometheus/g' "$src" | sed '/-- .* --/! s/"datasource":.*,/"datasource": "Prometheus",/g' ''
          else
            ''cat "$src"''
        } | jq '.title = "${title}"'${lib.optionalString excludeColonInstances " | jq '(.templating.list) |= map(if ((.name // \"\") | test(\"instance\")) then . + {regex:\"/^[^:]+$/\"} else . end)'"} > "$out"
      ''
  )
