{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.keyd.nixos.config.services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        leftmeta = "overload(meta, macro(rightmeta+z))";
        rightmeta = "overload(meta, macro(rightmeta+z))";
      };
    };
  };
}
