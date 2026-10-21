# Expected nat payloads of the unifi-nat-render check (site s, publicIPv4 192.0.2.1).
let
  filter =
    extra:
    {
      filter_type = "NONE";
      firewall_group_ids = [ ];
      invert_address = false;
      invert_port = false;
    }
    // extra;
  common = {
    enabled = true;
    exclude = false;
    ip_version = "IPV4";
    is_predefined = false;
    logging = false;
    pppoe_use_base_interface = false;
    setting_preference = "manual";
    protocol = "tcp_udp";
  };
in
{
  dnat =
    side: iface: index:
    common
    // {
      type = "DNAT";
      description = "c1-https-ingress dnat ${side}";
      in_interface = "\${data.restapi_object.unifi_network_${iface}.id}";
      ip_address = "10.1.0.1";
      port = "443";
      rule_index = index;
      source_filter = filter { };
      destination_filter = filter {
        filter_type = "ADDRESS_AND_PORT";
        address = "192.0.2.1";
        port = "443";
      };
    };
  masq =
    lan: index:
    common
    // {
      type = "MASQUERADE";
      description = "c1-https-ingress masquerade ${lan}";
      out_interface = "\${data.restapi_object.unifi_network_default.id}";
      rule_index = index;
      source_filter = filter {
        filter_type = "NETWORK_CONF";
        network_conf_id = "\${data.restapi_object.unifi_network_${lan}.id}";
      };
      destination_filter = filter {
        filter_type = "ADDRESS_AND_PORT";
        address = "10.1.0.1";
        port = "443";
      };
    };
}
