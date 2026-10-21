# The records with mode "nat" as custom NAT rules, one restapi_object each. A
# port forward to a target off the gateway's own networks masquerades every
# client; these rules masquerade hairpin clients only, so internet clients
# reach the target with their own address. The controller requires a DNAT's
# in_interface and a MASQUERADE's out_interface, both networkconf ids, looked
# up by `networks` names.
{
  lib,
  key,
  recordsOf,
  natRules,
}:
{
  env,
  site,
  publicIPv4,
  networks,
  forwards,
}:
let
  records = recordsOf "nat" env forwards;
  inherit (natRules { inherit key publicIPv4 networks; }) netKey rulesOf;
  rules = lib.concatMap rulesOf records;
  path = "/v2/api/site/${site}/nat";
in
if records == [ ] then
  { }
else
  assert lib.assertMsg (publicIPv4 != null) "unifi: nat port forwards need dns.publicIPv4";
  assert lib.assertMsg (networks != null) "unifi: nat port forwards need unifi.networks";
  {
    data.restapi_object = lib.genAttrs' (lib.unique ([ networks.wan ] ++ networks.lans)) (
      n:
      lib.nameValuePair (netKey n) {
        path = "/api/s/${site}/rest/networkconf";
        results_key = "data";
        search_key = "name";
        search_value = n;
        results_contains_object = true;
      }
    );
    # rule_index is unique per site and the controller assigns a clashing
    # one when none is sent, so each rule takes its position.
    resource.restapi_object = lib.listToAttrs (
      lib.imap1 (i: { name, value }: {
        inherit name;
        value = {
          inherit path;
          create_path = path;
          # No GET by id: read searches the list for the _id.
          read_path = "${path}/{id}";
          read_search = {
            search_key = "_id";
            search_value = "{id}";
          };
          update_path = "${path}/{id}";
          destroy_path = "${path}/{id}";
          # The controller adds _id, site_id and attr_* fields; drift is
          # judged on the declared ones.
          ignore_server_additions = true;
          data = builtins.toJSON (value // { rule_index = i; });
        };
      }) rules
    );
  }
