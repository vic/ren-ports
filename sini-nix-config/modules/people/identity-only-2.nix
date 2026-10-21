# Identity-only users, continued.
{ ren, ... }:
{
  ren.user.hugs = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
      ren.group."grafana.server-admins"
    ];
    identity = {
      displayName = "Shawn";
    };
  };

  ren.user.ellen = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
  };

  ren.user.jenn = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Jennifer Griffith-Delgado";
      email = "jdg9843@gmail.com";
    };
  };

  ren.user.zogger = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Pradeep Gollakota";
      email = "pradeepg26@gmail.com";
    };
  };

  ren.user.vincentpierre = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Vincent Pierre Berges";
      email = "vpsmbb@gmail.com";
    };
  };

  ren.user.you = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "You Zhou";
      email = "youzhou43@gmail.com";
    };
  };

  ren.user.yiran = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Yiran Tao";
      email = "yiran@alchemy.com";
    };
  };

  ren.user.louisabella = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Jei Jiao";
      email = "rabbit721@gmail.com";
    };
  };
}
