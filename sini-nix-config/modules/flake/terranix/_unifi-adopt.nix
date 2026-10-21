# unifi-adopt script body and the jq filter naming live port forwards.
{ workdir }:
{
  # Each live forward (rest/portforward) as an import block, its resource name
  # derived from its controller name as renderPortForwards keys it.
  portForwardJq = ''
    def nz: if . == null or . == "" then null else . end;
    def key: ((.name | nz) // ._id) | ascii_downcase | gsub("[^a-z0-9]+"; "_") | gsub("^_|_$"; "")
      | if test("^[0-9]") then "pf_" + . else . end;
    map({ to: "unifi_port_forward.\(key)", id: ._id })
    | if (map(.to) | unique | length) != length then error("unifi-adopt: two port forwards share a resource name") else . end
  '';

  script =
    { meta, portForwardImports }:
    ''
      api=$(jq -r .api_url ${meta})
      site=$(jq -r .site ${meta})
      # GET only. -k: the gateway's certificate is self-signed.
      bgp=$(curl -fksS -H @<(printf 'X-Api-Key: %s\n' "$UNIFI_API_KEY") \
        "$api/proxy/network/v2/api/site/$site/bgp/config")
      if [[ $(jq length <<<"$bgp") != 1 ]]; then
        echo "unifi-adopt: site $site has no BGP configuration to adopt" >&2
        exit 1
      fi
      pfs=$(curl -fksS -H @<(printf 'X-Api-Key: %s\n' "$UNIFI_API_KEY") \
        "$api/proxy/network/api/s/$site/rest/portforward" | jq .data)
      # unifi_bgp is a per-site singleton; its import id is the site name.
      # A port forward imports by its controller _id. Its config is the
      # declared one (port-forwards); a live forward with none fails the plan.
      jq --arg site "$site" --argjson pf "$(jq -f ${portForwardImports} <<<"$pfs")" \
        '{ import: ([ { to: .bgp, id: $site } ] + $pf) }' \
        ${meta} > ${workdir}/imports.tf.json
      # The flake reads imports.tf.json only once git tracks it.
      git add ${workdir}/imports.tf.json
      echo "unifi-adopt: site $site BGP config $(jq -r '.[0]._id' <<<"$bgp") ($(jq -r '.[0].description' <<<"$bgp"))"
      echo "unifi-adopt: $(jq length <<<"$pfs") port forwards:"
      jq -r '.[] | "  \(.name // "-")\t\(.proto)\twan \(.pfwd_interface // "-"):\(.dst_port // "-")\t-> \(.fwd // "-"):\(.fwd_port // "-")\tenabled=\(.enabled)"' <<<"$pfs"
      echo "unifi-adopt: wrote ${workdir}/imports.tf.json"
    '';
}
