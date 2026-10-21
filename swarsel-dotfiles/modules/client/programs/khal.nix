{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.khal.homeManager =
    {
      pkgs,
      ...
    }:
    let
      moduleName = "khal";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "khal" ];
        programs.${moduleName} = {
          enable = true;
          package = pkgs.khal;
        };
      };
    };
}
