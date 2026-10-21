# usersOf host -> users that get an account on host (den acl.nix resolveUser.enable
# + users.nix enableUnixAccount): group closure meets (env ++ host) system-access-groups in a system-scope group.
# Reads the user and group instances directly (R:216: `ren.<kind>` exists for every kind; instances are stratum 0).
{ ren, lib, ... }:
let
  names = map (r: r.name);
  # den scopeOf: oauth-grant (without posix) is kanidm scope, everything else system scope
  isSystem = g: lib.elem "posix" g.labels || !(lib.elem "oauth-grant" g.labels);
  gatesOf = host: names host.environment.system-access-groups ++ names host.system-access-groups;
in
{
  ren.helpers.usersOf =
    host:
    lib.filterAttrs (
      _: u:
      u.enableUnixAccount
      && lib.any (g: lib.elem g (gatesOf host) && isSystem ren.group.${g}) (
        ren.helpers.groupClosure ren.group (names u.groups)
      )
    ) ren.user;
}
