{ ren, ... }:
{
  ren.user.dvicory = {
    uid = 1006;
    groups = [
      ren.group.users
      ren.group.server-access
      ren.group."grafana.server-admins"
      ren.group."open-webui.admins"
      ren.group."media.admins"
    ];
    identity = {
      displayName = "dvicory";
      email = "dvicory@gmail.com";
      sshKeys = [
        {
          tag = "mbp-2021-32gb";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIABlT9eZfTQyCzzk9ddEfzaVqTJ1JBaMuwL2eZamj14i dvicory@mbp-2021-32gb";
        }
      ];
    };
  };

  ren.aspects.dvicory = {
    at = ren.user.dvicory;
    includes = [ ren.aspects.default ];
  };
}
