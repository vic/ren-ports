{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.obs-studio.homeManager =
    let
      moduleName = "obs-studio";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "obs-studio" ];
        programs.${moduleName}.enable = true;
      };
    };
}
