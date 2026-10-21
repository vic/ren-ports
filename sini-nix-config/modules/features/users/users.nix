# users: host-level mutableUsers + per-user account enrichment (uid/gid, ssh keys, groups, deterministicIds).
{ ren, lib, ... }:
let
  # den scopeOf: oauth-grant (without posix) is kanidm scope, everything else system scope (as usersOf).
  isSystem = g: lib.elem "posix" g.labels || !(lib.elem "oauth-grant" g.labels);
  systemGroups =
    user:
    lib.filter (n: isSystem ren.group.${n}) (
      ren.helpers.groupClosure ren.group (map (g: g.name) user.groups)
    );
in
{
  ren.aspects.users = {
    nixos.users.mutableUsers = false;
  };

  ren.aspects.users-enrich = {
    at = ren.kinds.user;
    nixos =
      { user, ... }:
      {
        users.deterministicIds.${user.name} = lib.optionalAttrs (user.uid != null) {
          inherit (user) uid;
          gid = if user.gid != null then user.gid else user.uid;
          subUidRanges = [
            {
              startUid = 100000 + ((user.uid - 1000) * 65536);
              count = 65536;
            }
          ];
          subGidRanges = [
            {
              startGid = 100000 + ((user.uid - 1000) * 65536);
              count = 65536;
            }
          ];
        };
        users.groups.${user.name} = lib.optionalAttrs (user.uid != null) {
          gid = if user.gid != null then user.gid else user.uid;
        };
      };
    account = { user, ... }: {
      openssh.authorizedKeys.keys = map (k: k.key) user.identity.sshKeys;
      # den acl.nix resolveUser.systemGroups: transitive group closure kept to system-scope groups.
      extraGroups = systemGroups user;
      inherit (user) linger;
      description = lib.mkDefault user.identity.displayName;
    };
  };
}
