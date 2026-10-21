# systemd-networkd .network config for one interface (managed or unmanaged).
{ lib, environment }:
let
  inherit (lib) length optionalAttrs optionals;

  defaultNet = environment.networks.default or { };

  # Common route configuration for TCP optimization
  mkRoute =
    gateway: extra:
    {
      Gateway = gateway;
      InitialCongestionWindow = 50;
      InitialAdvertisedReceiveWindow = 50;
    }
    // extra;

  effectiveDhcp =
    ifCfg:
    if ifCfg.dhcp != null then
      ifCfg.dhcp
    else if !(ifCfg.managed or true) then
      "none"
    else if length (ifCfg.ipv4 or [ ]) > 0 then
      "ipv6"
    else
      "yes";

  effectiveLinkLocal =
    ifCfg:
    if ifCfg.linkLocal != null then
      ifCfg.linkLocal
    else if ifCfg.managed or true then
      "ipv6"
    else
      "no";

  requiredForOnline = ifCfg: if ifCfg.requiredForOnline != null then ifCfg.requiredForOnline else "routable";

  mtu = ifCfg: optionalAttrs (ifCfg.mtu != null) { MTUBytes = toString ifCfg.mtu; };

  mkManaged =
    ifCfg:
    let
      ipv4Addrs = ifCfg.ipv4 or [ ];
    in
    {
      networkConfig = {
        Address = ipv4Addrs ++ (ifCfg.ipv6 or [ ]);
        DHCP = effectiveDhcp ifCfg;
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = if ifCfg.privacyExtensions != null then ifCfg.privacyExtensions else "yes";
        LinkLocalAddressing = effectiveLinkLocal ifCfg;
        DNS = defaultNet.dnsServers or [ ];
        DNSOverTLS = true;
        # No per-link DNSSEC: it would override services.resolved.dnssec. The
        # upstreams validate; resolved's own validation fails CNAME chains into
        # unsigned zones (e.g. registry.k8s.io -> us-west2-docker.pkg.dev).
      };
      # Drop SLAAC address autoconf when an interface opts out (DHCPv6/static-only
      # addressing gives one deterministic GUA); RA still gives prefix + default route.
      ipv6AcceptRAConfig = optionalAttrs (ifCfg.acceptRAAutonomousPrefix or null != null) {
        UseAutonomousPrefix = ifCfg.acceptRAAutonomousPrefix;
      };
      dhcpV6Config = {
        UseDelegatedPrefix = true;
        PrefixDelegationHint = "::/64";
      };
      routes = optionals (length ipv4Addrs > 0) [
        (mkRoute (defaultNet.gatewayIp or null) { })
        (mkRoute (defaultNet.gatewayIpV6 or null) {
          Destination = "::/0";
          GatewayOnLink = true;
        })
      ];
      linkConfig = {
        RequiredForOnline = requiredForOnline ifCfg;
      }
      // mtu ifCfg;
    };

  mkUnmanaged = ifCfg: {
    networkConfig = {
      Address = (ifCfg.ipv4 or [ ]) ++ (ifCfg.ipv6 or [ ]);
      LinkLocalAddressing = effectiveLinkLocal ifCfg;
    }
    // optionalAttrs (effectiveDhcp ifCfg != "none") { DHCP = effectiveDhcp ifCfg; };
    linkConfig = {
      ActivationPolicy = "up";
      RequiredForOnline = requiredForOnline ifCfg;
    }
    // mtu ifCfg;
  };
in
ifCfg: if ifCfg.managed or true then mkManaged ifCfg else mkUnmanaged ifCfg
