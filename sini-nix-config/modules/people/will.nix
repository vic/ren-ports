{ ren, ... }:
{
  ren.user.will = {
    uid = 1002;
    groups = [
      ren.group.users
      ren.group.workstation-access
    ];
    identity = {
      displayName = "Will Bryant";
      email = "will.t.bryant@gmail.com";
      sshKeys = [
        {
          tag = "best-laptop-ever";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKKUMmeJtEOYi6rU0tumxlrZjH9Y3FCyOhVFIpu3LF1 will.t.bryant@gmail.com";
        }
      ];
    };
  };

  ren.aspects.will = {
    at = ren.user.will;
    includes = [ ren.aspects.default ];
  };
}
