# Group instances: user roles and system login gates.
{ ren, ... }:
{
  ren.group.admins = {
    labels = [ "user-role" "oauth-grant" ];
    description = "Full administrative access";
  };
  ren.group.users = {
    labels = [ "user-role" "oauth-grant" ];
    description = "Standard user access";
    members = [
      ren.group.admins
    ];
  };
  ren.group.system-access = {
    labels = [ "user-role" "posix" ];
    description = "Login access to all hosts";
  };
  ren.group.workstation-access = {
    labels = [ "user-role" "posix" ];
    description = "Login access to workstation hosts";
    members = [
      ren.group.system-access
    ];
  };
  ren.group.server-access = {
    labels = [ "user-role" "posix" ];
    description = "Login access to server hosts";
    members = [
      ren.group.system-access
    ];
  };
}
