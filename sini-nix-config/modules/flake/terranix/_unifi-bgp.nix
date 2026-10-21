# The gateway's raw FRR bgpd config: one peer group per remote ASN, one
# neighbor per bgp-peers record. Raw, not the provider's structured peers:
# its template forces ebgp-requires-policy, redistribute connected,
# next-hop-self, multihop and timers, and cannot set maximum-paths.
{ lib }:
{
  name,
  cidr,
  asn,
  routerId,
  peers,
}:
assert lib.assertMsg (asn != null) "unifi: environment ${name} sets no networks.default.gatewayAsn";
let
  neighbors = lib.sort (a: b: a.asn < b.asn || (a.asn == b.asn && a.ip < b.ip)) (
    map (
      p:
      if p.asn == asn then
        throw "unifi: bgp peer ${p.hostname} shares the gateway's AS ${toString asn}; the gateway runs eBGP only"
      else
        p
    ) (builtins.filter (p: p.ip != routerId) peers)
  );
  asns = lib.unique (map (p: p.asn) neighbors);
  group = a: "as${toString a}";
  groupLines =
    a:
    [
      " !"
      " neighbor ${group a} peer-group"
      " neighbor ${group a} remote-as ${toString a}"
      " neighbor ${group a} soft-reconfiguration inbound"
    ]
    ++ lib.concatMap (p: [
      " neighbor ${p.ip} peer-group ${group a}"
      " neighbor ${p.ip} description ${p.hostname}"
    ]) (builtins.filter (p: p.asn == a) neighbors);
in
lib.concatStringsSep "\n" (
  [
    "! -*- bgp -*-"
    "!"
    "! FRR BGP Configuration for Unifi Router"
    "! Environment: ${name}"
    "! Management Network: ${cidr}"
    "!"
    "frr defaults traditional"
    "!"
    "hostname edge-${name}"
    "password zebra"
    "!"
    "router bgp ${toString asn}"
    " bgp router-id ${routerId}"
    " no bgp ebgp-requires-policy"
    " bgp bestpath as-path multipath-relax"
    " maximum-paths 8"
  ]
  ++ lib.concatMap groupLines asns
  ++ [
    " !"
    " address-family ipv4 unicast"
  ]
  ++ map (a: "  neighbor ${group a} activate") asns
  ++ [
    " exit-address-family"
    "!"
    "line vty"
    "!"
    ""
  ]
)
