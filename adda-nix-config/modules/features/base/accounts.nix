# Accounts: every user is a normal, primary (wheel) user of its host (den define-user + primary-user + setUserName).
{ ren, ... }:
{
  ren.aspects.account = {
    at = ren.kinds.user;
    account =
      { user, ... }:
      {
        name = user.name;
        home = "/home/${user.name}";
        isNormalUser = true;
        description = user.realName;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
          "camera"
          "kvm"
          "libvirtd"
          "lp"
          "scanner"
          "docker"
        ];
        openssh.authorizedKeys.keys = user.authorizedKeys;
      };
    os =
      { user, ... }:
      {
        users.groups.uinput.members = [ user.name ];
        users.groups.input.members = [ user.name ];
      };
    homeManager =
      { user, ... }:
      {
        home.username = user.name;
        home.homeDirectory = "/home/${user.name}";
      };
  };
}
