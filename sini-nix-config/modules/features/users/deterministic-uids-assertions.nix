{ ... }:
{
  ren.aspects.users-deterministic-uids.nixos =
    { config, lib, ... }:
    {
      assertions =
        lib.concatLists (
          lib.mapAttrsToList (name: user: [
            {
              assertion = user.uid != null;
              message = "den: non-deterministic uid for '${name}', assign via users.deterministicIds";
            }
            {
              assertion = !user.autoSubUidGidRange;
              message = "den: non-deterministic subUids/subGids for: ${name}";
            }
          ]) config.users.users
        )
        ++ lib.mapAttrsToList (name: group: {
          assertion = group.gid != null;
          message = "den: non-deterministic gid for '${name}', assign via users.deterministicIds";
        }) config.users.groups;
    };
}
