# Fleet: root of the scope tree. One tailnet, one DNS policy for every machine (den kept these on user opt.network).
{ ren, lib, inputs, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  ren.kinds.fleet = {
    below = [
      ren.kinds.system
      ren.kinds.host
    ];
    tailnet = opt t.str "rohu-ling.ts.net";
    # DoH/DoT/DoQ upstreams: a set, not a fallback order (blocky honours order with strategy "strict")
    upstreamDns = opt (t.listOf t.str) [
      "quic://dns.quad9.net"
      "https://dns.quad9.net/dns-query"
      "quic://dns.adguard-dns.com"
      "https://dns.adguard-dns.com/dns-query"
    ];
    # plain resolvers for bootstrap and the stub list; IPv4 first (glibc MAXNS=3)
    plainDns = opt (t.listOf t.str) [
      "9.9.9.9"
      "149.112.112.112"
      "2620:fe::fe"
      "2620:fe::9"
    ];
    ci = opt t.bool false; # CI evaluation: no bootloader, dummy root
  };
  ren.fleet.addax = { };

  # systems: per-system flake outputs (packages, apps, checks) live in their scopes
  ren.kinds.system.legacyPackages = t.raw;
  ren.system.x86_64-linux.legacyPackages = inputs.nixpkgs.legacyPackages.x86_64-linux;
}
