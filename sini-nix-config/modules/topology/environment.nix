# Environments: machines and clusters of one deployment tier, plus its shared facts.
{ ren, lib, ... }:
let
  inherit (ren.lib) same opt maybe;
  t = lib.types;
  inEnv = xs: s: lib.filterAttrs (_: x: same x.environment s.environment) xs;
  delegationT = t.submodule {
    options.metricsTo = maybe ren.kinds.environment;
    options.authTo = maybe ren.kinds.environment;
    options.logsTo = maybe ren.kinds.environment;
  };
  unifiT = t.submodule {
    options.site = opt t.str "default";
    options.wans = opt (t.listOf t.str) [ "wan" ];
    # controller network names for nat port forwards; null = no nat
    options.networks = maybe (t.submodule {
      options.wan = lib.mkOption { type = t.str; };
      options.lans = lib.mkOption { type = t.listOf t.str; };
    });
    options.bgp = opt (t.submodule {
      options.enabled = opt t.bool true;
      options.description = opt t.str "";
      options.uploadFileName = opt t.str "";
    }) { };
  };
in
{
  ren.kinds.environment = {
    below = [
      ren.kinds.host
      ren.kinds.mac
      ren.kinds.droid
      ren.kinds.cluster
    ];
    spawns = {
      host = inEnv ren.host;
      mac = inEnv ren.mac;
      droid = inEnv ren.droid;
      cluster = inEnv ren.cluster;
    };
    id = opt t.int 0;
    domain = t.str; # base domain
    secretPath = maybe t.path; # set per instance as a path literal (.secrets/env/<name>)
    wirelessSecretsFile = maybe t.path; # set per instance (secretPath + "/wpa_supplicant_psks.age")
    timezone = opt t.str "UTC";
    tags = opt (t.attrsOf t.str) { };
    delegation = opt delegationT { };
    cluster = maybe ren.kinds.cluster; # was monitoring.ingest
    system-access-groups = opt (t.listOf ren.kinds.group) [ ];
    group = maybe ren.kinds.group;
    # user name (string key) -> groups (refs), as den access
    access = opt (t.attrsOf (t.listOf ren.kinds.group)) { };
    unifi = maybe unifiT;
  };
}
