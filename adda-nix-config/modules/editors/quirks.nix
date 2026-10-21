# Editor extension points (den quirks): language aspects contribute, editor aspects own the rest.
# Mergeable contributions that need pkgs are classes written into one hm option (den mkMerge pools).
# Plain string lists (extension ids) are channels: the editor turns the whole list into packages.
{ ren, ... }:
let
  inherit (ren.lib) and within;
  inHost = and [
    ren.kinds.user
    (within ren.kinds.host)
  ];
  class = paths: {
    at = inHost;
    into = ren.helpers.intoHm paths;
  };
  ids = {
    fold = ren.lib.fold.set;
    at = ren.kinds.user;
    to = e: e;
  };
in
{
  ren.classes = {
    helixSettings = class [
      [
        "programs"
        "helix"
        "settings"
      ]
    ];
    helixLanguages = class [
      [
        "programs"
        "helix"
        "languages"
      ]
    ];
    helixPackages = class [
      [
        "home"
        "packages"
      ]
      [
        "programs"
        "helix"
        "extraPackages"
      ]
    ];
    zedSettings = class [
      [
        "programs"
        "zed-editor"
        "userSettings"
      ]
    ];
    zedPackages = class [
      [
        "programs"
        "zed-editor"
        "extraPackages"
      ]
    ];
    vscodiumSettings = class [
      [
        "programs"
        "vscodium"
        "profiles"
        "default"
        "userSettings"
      ]
    ];
  };
  ren.channels.zed-extensions = ids;
  ren.channels.vscodium-extensions = ids;
}
