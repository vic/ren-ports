# Environment network facts: networks, services, certificates, mail, acme, dns, location.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
  wirelessT = t.submodule {
    options.ssid = lib.mkOption { type = t.str; };
    options.pskRef = lib.mkOption { type = t.str; };
  };
  networkT = t.submodule {
    options.cidr = lib.mkOption { type = t.str; };
    options.ipv6_cidr = maybe t.str;
    options.description = opt t.str "";
    options.gatewayIp = maybe t.str;
    options.gatewayIpV6 = maybe t.str;
    options.dnsServers = opt (t.listOf t.str) [ ];
    options.assignments = opt (t.attrsOf t.str) { };
    options.gatewayAsn = maybe ren.helpers.types.positive;
    options.wireless = maybe wirelessT;
  };
  serviceT = t.submodule {
    options.domain = maybe t.str;
    options.delegateTo = maybe ren.kinds.environment;
  };
  issuerT = t.submodule {
    options.ageKeyFile = maybe t.str;
  };
in
{
  ren.kinds.environment = {
    networks = opt (t.attrsOf networkT) { };
    services = opt (t.attrsOf serviceT) { };
    certificates.issuers = opt (t.attrsOf issuerT) { };
    email = {
      domain = opt t.str "";
      adminEmail = opt t.str "";
    };
    acme = {
      server = opt t.str "https://acme-v02.api.letsencrypt.org/directory";
      dnsProvider = opt t.str "cloudflare";
      dnsResolver = opt t.str "1.1.1.1:53";
    };
    dns = opt (t.submodule { options.publicIPv4 = maybe t.str; }) { }; # a bare nested group has no default: dev omits dns
    location = {
      country = opt t.str "US";
      region = opt t.str "";
    };
  };
}
