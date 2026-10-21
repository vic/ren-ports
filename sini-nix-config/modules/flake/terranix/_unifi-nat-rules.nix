# One nat record as custom NAT rules (v2 `nat`):
#   <key>_dnat_wan    public address:wanPort in on the WAN -> forward
#   <key>_dnat_<lan>  the same in on each LAN (hairpin)
#   <key>_masq_<lan>  each LAN's clients to forward, out the first LAN
# Ports are the controller's strings; a /32 filter address is refused, so
# addresses are bare.
{ key, publicIPv4, networks }:
let
  netKey = n: "unifi_network_${key n}";
  netId = n: "\${data.restapi_object.${netKey n}.id}";
  singlePort =
    r: p:
    if builtins.match "[0-9]+" p != null then
      p
    else
      throw "unifi: nat port forward ${r.name} needs a single port, not ${p}";
  filter =
    extra:
    {
      filter_type = "NONE";
      firewall_group_ids = [ ];
      invert_address = false;
      invert_port = false;
    }
    // extra;
  rule =
    extra:
    {
      enabled = true;
      exclude = false;
      ip_version = "IPV4";
      is_predefined = false;
      logging = false;
      pppoe_use_base_interface = false;
      setting_preference = "manual";
    }
    // extra;
in
{
  inherit netKey;
  rulesOf =
    { name, value }:
    let
      r = value;
      dnat = side: iface: {
        name = "${name}_dnat_${side}";
        value = rule {
          type = "DNAT";
          description = "${r.name} dnat ${side}";
          inherit (r) protocol;
          in_interface = netId iface;
          ip_address = r.forward.ip;
          port = singlePort r r.forward.port;
          source_filter = filter { };
          destination_filter = filter {
            filter_type = "ADDRESS_AND_PORT";
            address = publicIPv4;
            port = singlePort r r.wanPort;
          };
        };
      };
      masq = lan: {
        name = "${name}_masq_${key lan}";
        value = rule {
          type = "MASQUERADE";
          description = "${r.name} masquerade ${key lan}";
          inherit (r) protocol;
          out_interface = netId (builtins.head networks.lans);
          source_filter = filter {
            filter_type = "NETWORK_CONF";
            network_conf_id = netId lan;
          };
          destination_filter = filter {
            filter_type = "ADDRESS_AND_PORT";
            address = r.forward.ip;
            port = singlePort r r.forward.port;
          };
        };
      };
    in
    [ (dnat "wan" networks.wan) ]
    ++ map (lan: dnat (key lan) lan) networks.lans
    ++ map masq networks.lans;
}
