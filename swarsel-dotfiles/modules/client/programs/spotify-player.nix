{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.spotify-player.homeManager =
    let
      moduleName = "spotify-player";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "spotify-player" ];
        programs.${moduleName}.enable = true;
      };
    };
}
