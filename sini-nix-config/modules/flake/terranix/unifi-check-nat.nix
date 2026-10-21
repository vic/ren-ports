# Fixture: a nat record renders as the WAN DNAT, a hairpin DNAT per LAN and
# a masquerade per LAN out of the first, with exact payloads; a forward record
# and another environment's nat record render no rule; a port list, an unknown
# mode, a forward on the same port and a missing networks are refused.
{ ren, ... }:
{
  ren.aspects.flake-terranix-unifi-check-nat = {
    at = ren.kinds.system;
    checks =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        inherit (pkgs) lib;
        inherit (import ./_unifi-lib.nix { inherit lib; }) key recordsOf;
        renderNat = import ./_unifi-nat.nix {
          inherit lib key recordsOf;
          natRules = import ./_unifi-nat-rules.nix;
        };
        inherit (import ./_unifi-check-nat-expect.nix) dnat masq;
        nat = (import ./_unifi-check-pf-data.nix).cluster // {
          mode = "nat";
        };
        plain = removeAttrs nat [ "mode" ];
        args = {
          env = "t";
          site = "s";
          publicIPv4 = "192.0.2.1";
          networks = {
            wan = "Internet 1";
            lans = [
              "Default"
              "dev"
            ];
          };
          forwards = [
            nat
            (plain // { name = "ssh"; wanPort = "22"; })
            (nat // { environment = "u"; name = "c2"; })
          ];
        };
        rendered = renderNat args;
        rules = rendered.resource.restapi_object;
        payload = n: builtins.fromJSON rules.${n}.data;
        refused = a: !(builtins.tryEval (builtins.deepSeq (renderNat (args // a)) null)).success;
        ok =
          builtins.attrNames rules == [
            "c1_https_ingress_dnat_default"
            "c1_https_ingress_dnat_dev"
            "c1_https_ingress_dnat_wan"
            "c1_https_ingress_masq_default"
            "c1_https_ingress_masq_dev"
          ]
          && payload "c1_https_ingress_dnat_wan" == dnat "wan" "internet_1" 1
          && payload "c1_https_ingress_dnat_default" == dnat "default" "default" 2
          && payload "c1_https_ingress_dnat_dev" == dnat "dev" "dev" 3
          && payload "c1_https_ingress_masq_default" == masq "default" 4
          && payload "c1_https_ingress_masq_dev" == masq "dev" 5
          && rules.c1_https_ingress_dnat_wan.read_search == {
            search_key = "_id";
            search_value = "{id}";
          }
          && rules.c1_https_ingress_dnat_wan.destroy_path == "/v2/api/site/s/nat/{id}"
          && builtins.attrNames rendered.data.restapi_object == [
            "unifi_network_default"
            "unifi_network_dev"
            "unifi_network_internet_1"
          ]
          && rendered.data.restapi_object.unifi_network_dev.search_value == "dev"
          && renderNat (args // { forwards = [ plain ]; }) == { }
          && refused { forwards = [ (nat // { wanPort = "443,8443"; }) ]; }
          && refused { forwards = [ (nat // { mode = "dnat"; }) ]; }
          && refused { forwards = [ nat (plain // { name = "c1-forward"; }) ]; }
          && refused { networks = null; };
      in
      {
        unifi-nat-render =
          assert lib.assertMsg ok "unifi-nat-render:\n${builtins.toJSON rendered}";
          pkgs.writeText "unifi-nat-render" (builtins.toJSON rendered);
      };
  };
}
