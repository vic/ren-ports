# a-m channels, editors: codium extension ids and settings, user -> user.
{ ren, ... }:
{
  ren.channels.codium-extensions = {
    fold = ren.lib.fold.set;
    at = ren.kinds.user;
    to = e: e;
  };

  ren.channels.codium-settings = {
    fold = ren.lib.fold.attrs;
    at = ren.kinds.user;
    to = e: e;
  };
}
