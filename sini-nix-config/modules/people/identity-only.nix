# Identity-only users (Kanidm/SSO, no Unix accounts, no system-access groups).
{ ren, ... }:
{
  ren.user.json = {
    enableUnixAccount = false;
    groups = [
      ren.group.admins
    ];
  };

  ren.user.json_user = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Jason-user";
      email = "jason_user@json64.dev";
    };
  };

  ren.user.greco = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Jason Greco";
      email = "jasonagreco@gmail.com";
    };
  };

  ren.user.taiche = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Chris Tai";
      email = "christai@gmail.com";
    };
  };

  ren.user.jennism = {
    enableUnixAccount = false;
    groups = [
      ren.group.users
    ];
    identity = {
      displayName = "Jennifer Ng";
      email = "jenn.ng@gmail.comm";
    };
  };
}
