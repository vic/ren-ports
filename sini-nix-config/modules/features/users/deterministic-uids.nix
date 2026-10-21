# Deterministic UIDs/GIDs: option module `users.deterministicIds` auto-assigns uid/gid via mkDefault
# to users/groups; uidGid registry lives in deterministic-uids-ids.nix; assertions in -assertions.nix.
{ ... }:
{
  ren.aspects.users-deterministic-uids.nixos =
    { config, lib, ... }:
    {
      options.users = {
        deterministicIds = lib.mkOption {
          default = { };
          description = "Maps user/group name to expected uid/gid values.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                uid = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                };
                gid = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                };
                subUidRanges = lib.mkOption {
                  type = lib.types.listOf (
                    lib.types.submodule {
                      options = {
                        startUid = lib.mkOption { type = lib.types.int; };
                        count = lib.mkOption { type = lib.types.int; };
                      };
                    }
                  );
                  default = [ ];
                };
                subGidRanges = lib.mkOption {
                  type = lib.types.listOf (
                    lib.types.submodule {
                      options = {
                        startGid = lib.mkOption { type = lib.types.int; };
                        count = lib.mkOption { type = lib.types.int; };
                      };
                    }
                  );
                  default = [ ];
                };
              };
            }
          );
        };

        users = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                config = {
                  uid = lib.mkIf ((config.users.deterministicIds.${name}.uid or null) != null) (
                    lib.mkDefault config.users.deterministicIds.${name}.uid
                  );
                  subUidRanges = lib.mkIf ((config.users.deterministicIds.${name}.subUidRanges or [ ]) != [ ]) (
                    lib.mkDefault config.users.deterministicIds.${name}.subUidRanges
                  );
                  subGidRanges = lib.mkIf ((config.users.deterministicIds.${name}.subGidRanges or [ ]) != [ ]) (
                    lib.mkDefault config.users.deterministicIds.${name}.subGidRanges
                  );
                };
              }
            )
          );
        };

        groups = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                config.gid = lib.mkIf ((config.users.deterministicIds.${name}.gid or null) != null) (
                  lib.mkDefault config.users.deterministicIds.${name}.gid
                );
              }
            )
          );
        };
      };
    };
}
