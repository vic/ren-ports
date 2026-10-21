# hipfire settings options, part 3: daemon environment and user (see hipfire.nix).
{ lib, types, ... }:
{
  environment = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Extra environment variables (HIPFIRE_*) for the daemon.";
  };

  userService = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Run as a user-level systemd service instead of a system service (no dedicated user).";
  };

  user = lib.mkOption {
    type = lib.types.str;
    default = "hipfire";
    description = "User to run the daemon as (system mode only).";
  };

  group = lib.mkOption {
    type = lib.types.str;
    default = "hipfire";
    description = "Group to run the daemon as (system mode only).";
  };
}
