# a-m channels, overlays: home-manager modules, user -> user imports.
{ ren, ... }:
{
  ren.channels.homeManagerModules = {
    fold = ren.lib.fold.list;
    at = ren.kinds.user;
    to = e: e;
    # forwards as homeManager class content: its branches route host, mac and droid users (platforms/home-manager.nix)
    into = { ... }: ms: { homeManager.imports = ms; };
  };
}
