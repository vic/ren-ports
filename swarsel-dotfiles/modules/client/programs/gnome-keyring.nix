{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects = {
    gnome-keyring.homeManager =
      {
        osConfig ? null,
        lib,
        ...
      }:
      {
        config = {
          swarselsystems.enabledHomeModules = [ "gnome-keyring" ];
          services.gnome-keyring = lib.mkIf (osConfig == null) {
            enable = true;
          };
        };
      };
    gnome-keyring.nixos.config = {
      services.gnome.gnome-keyring.enable = true;
      programs.seahorse.enable = true;
    };
  };
}
