{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.fuzzel.homeManager.config = {
    swarselsystems.enabledHomeModules = [ "fuzzel" ];
    programs.fuzzel = {
      enable = true;
      settings = {
        border.radius = "0";
        main = {
          layer = "overlay";
          lines = "10";
          width = "40";
        };
      };
    };
  };
}
