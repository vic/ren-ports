# Clusters: leaf under an environment; hosts are refs. sopsAgeRecipient is a helper.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
  networkT = t.submodule {
    options.cidr = lib.mkOption { type = t.str; };
    options.ipv6_cidr = maybe t.str;
    options.description = opt t.str "";
    options.gatewayIp = maybe t.str;
    options.gatewayIpV6 = maybe t.str;
    options.dnsServers = opt (t.listOf t.str) [ ];
    options.assignments = opt (t.attrsOf t.str) { };
  };
  nfsT = t.submodule {
    options.server = lib.mkOption { type = t.str; };
    options.share = lib.mkOption { type = t.str; };
    options.type = opt (t.enum [ "storageclass" "backup" ]) "storageclass";
  };
in
{
  ren.kinds.cluster = {
    environment = ren.kinds.environment;
    role = opt (t.nullOr t.str) "k3s";
    kubeVersion = maybe t.str;
    hosts = t.listOf ren.kinds.host;
    secretPath = maybe t.path;
    networks = opt (t.attrsOf networkT) { };
    nfsVolumes = opt (t.attrsOf nfsT) { };
  };
}
