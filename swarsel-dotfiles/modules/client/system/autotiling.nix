{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.autotiling.homeManager =
    let
      moduleName = "autotiling";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "autotiling" ];
        services.${moduleName} = {
          enable = true;
          systemdTarget = "sway-session.target";
        };
      };
    };
}
