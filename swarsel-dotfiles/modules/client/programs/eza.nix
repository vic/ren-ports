{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.eza.homeManager.config = {
    swarselsystems.enabledHomeModules = [ "eza" ];
    programs.eza = {
      enable = true;
      extraOptions = [
        "-l"
        "--group-directories-first"
      ];
      git = true;
      icons = "auto";
    };
  };
}
