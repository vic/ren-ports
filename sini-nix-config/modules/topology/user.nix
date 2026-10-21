# Users: identity and unix account facts (den user schema).
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
  sshKeyT = t.submodule {
    options.tag = maybe t.str;
    options.key = lib.mkOption { type = t.str; };
  };
  principalT = t.submodule {
    options.provider = lib.mkOption { type = t.enum [ "kanidm" "google" ]; };
    options.email = lib.mkOption { type = t.str; };
  };
  identityT = t.submodule {
    options.displayName = opt t.str "";
    options.email = maybe t.str;
    options.gpgKey = maybe t.str;
    options.sshKeys = opt (t.listOf sshKeyT) [ ];
    # null = kanidm principal from identity.email (ren.helpers.sshOidcPrincipalsOf)
    options.sshOidcPrincipals = maybe (t.listOf principalT);
  };
in
{
  ren.kinds.user = {
    identity = opt identityT { };
    secretPath = maybe t.path; # set per user as a path literal (.secrets/users/<name>)
    uid = maybe t.int;
    gid = maybe t.int;
    linger = opt t.bool false;
    syncthingOffset = maybe t.int; # null = uid - 1000 (ren.helpers.syncthingOffsetOf)
    enableUnixAccount = opt t.bool true;
    groups = opt (t.listOf ren.kinds.group) [ ];
    # den extra-features/excluded-features/include-host-features are aspect `includes`/`excludes` on the user's aspect (README:264).
  };
}
