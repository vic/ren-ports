# Machine (abstract): what every host, mac, droid and guest is.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
  exporterT = t.submodule {
    options.port = lib.mkOption { type = t.int; };
    options.path = opt t.str "/metrics";
    options.interval = opt t.str "30s";
  };
in
{
  ren.kinds.machine = {
    system = ren.kinds.system;
    channel = ren.kinds.channel;
    environment = ren.kinds.environment;
    system-owner = maybe ren.kinds.user;
    system-access-groups = opt (t.listOf ren.kinds.group) [ ];
    facts = maybe t.path; # set per instance as a path literal (hosts/<name>/facter.json)
    secretPath = maybe t.path; # set per instance as a path literal (.secrets/hosts/<name>)
    public_key = maybe t.path;
    exporters = opt (t.attrsOf exporterT) { };
    deployment = opt (t.submodule { options.user = opt t.str "sini"; }) { }; # bare nested group has no default
    # ipv4 ipv6 deployment.address deployment.tags: helpers, not fields (derived)
  };
}
