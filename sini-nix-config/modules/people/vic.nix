{ ren, ... }:
{
  ren.user.vic = {
    uid = 1003;
    groups = [
      ren.group.users
      ren.group.admins
      ren.group.server-access
      ren.group."grafana.server-admins"
      ren.group."open-webui.admins"
      ren.group.workstation-access # pair-programming login on workstations; no sudo (not system-owner)
    ];
    identity = {
      displayName = "Victor Borja";
      email = "vborja@apache.org";
      sshKeys = [
        {
          tag = "a";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHnnXIJy33RQdITOCDAv1fxBU41Uft1SJOre5S9YdVGH a@github.com";
        }
        {
          tag = "b";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPSIumgbAMxIWAw4Slb2j09ZTz9AgVqdSykKgoQumyqo b@github.com";
        }
      ];
    };
  };

  ren.aspects.vic = {
    at = ren.user.vic;
    includes = [ ren.aspects.default ];
  };
}
