{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects = {
    blueman-applet.homeManager.config = {
      swarselsystems.enabledHomeModules = [ "blueman-applet" ];
      services.blueman-applet.enable = true;
    };
    blueman.nixos.config.services = {
      blueman.enable = true;
      hardware.bolt.enable = true;
    };
  };
}
