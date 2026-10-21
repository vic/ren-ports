# dns-adopt script body (den flake-parts/terranix/terranix.nix).
{
  workdir,
  declared,
  tofu,
  scripts,
  exe,
}:
''
  api=https://api.cloudflare.com/client/v4
  cf() { curl -fsS -H @<(printf 'Authorization: Bearer %s\n' "$CLOUDFLARE_API_TOKEN") "$api$1"; }

  existing='[]'
  for zone in $(jq -r '[.[].zone] | unique | .[]' ${declared}); do
    zone_id=$(cf "/zones?name=$zone" | jq -r '.result[0].id // empty')
    if [[ -z $zone_id ]]; then
      echo "dns-adopt: zone $zone not visible to the token" >&2
      exit 1
    fi
    # ponytail: one page of 5000 records per zone; paginate if a zone ever outgrows it.
    records=$(cf "/zones/$zone_id/dns_records?per_page=5000" \
      | jq --arg zid "$zone_id" '[.result[] | {name, type, content, rid: .id, id: "\($zid)/\(.id)"}]')
    existing=$(jq -n --argjson a "$existing" --argjson b "$records" '$a + $b')
  done

  # Records already in state, by Cloudflare record id. The previous
  # import blocks may name addresses this config no longer declares,
  # so they are set aside while the state is read.
  imports=${workdir}/imports.tf.json
  if [[ -e $imports ]]; then mv "$imports" "$imports.prev"; fi
  trap 'rm -f "$identity"; if [[ -e $imports.prev ]]; then mv "$imports.prev" "$imports"; fi' EXIT
  ${exe scripts.init} >&2
  state=$(${tofu} show -json | jq '[.values.root_module.resources[]? | select(.type == "cloudflare_dns_record") | {address, rid: .values.id}]')

  # A CNAME cannot share its name with another type: that blocks the create.
  jq -r --argjson ex "$existing" '.[] as $d
    | $ex[] | select(.name == $d.name and .type != $d.type and (.type == "CNAME" or $d.type == "CNAME"))
    | "dns-adopt: \(.name) exists as \(.type), declared \($d.type); resolve by hand"' \
    ${declared} >&2

  # Several records share a name, so a live record matches on name, type
  # and content. One already in state under another address moves; one
  # not in state is imported.
  jq --argjson ex "$existing" --argjson st "$state" '
    [ .[] as $d | $ex[] | select(.name == $d.name and .type == $d.type and .content == $d.content)
      | . as $e | { to: $d.address, id: $e.id, from: ([ $st[] | select(.rid == $e.rid) | .address ] | first) } ]
    | { import: [ .[] | select(.from == null) | { to, id } ],
        moved: [ .[] | select(.from != null and .from != .to) | { from, to } ] }' \
    ${declared} > "$imports.new"
  mv "$imports.new" "$imports"
  rm -f "$imports.prev"
  echo "dns-adopt: $(jq length ${declared}) declared; $(jq '.import | length' "$imports") to import, $(jq '.moved | length' "$imports") to move; wrote $imports"
''
