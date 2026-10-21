{ ren, ... }:
{
  ren.user.shuo = {
    uid = 1001;
    groups = [
      ren.group.users
      ren.group.admins
      ren.group.workstation-access
    ];
    identity = {
      displayName = "Shuo Diao";
      email = "shuo.diao.nku@gmail.com";
    };
  };

  ren.aspects.shuo = {
    at = ren.user.shuo;
    includes = [ ren.aspects.default ];
  };
}
