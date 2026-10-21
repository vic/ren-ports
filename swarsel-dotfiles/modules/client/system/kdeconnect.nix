{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.kdeconnect.homeManager.config = {
    swarselsystems.enabledHomeModules = [ "kdeconnect" ];
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}
