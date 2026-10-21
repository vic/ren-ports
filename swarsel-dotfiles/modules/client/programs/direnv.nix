{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.direnv.homeManager.config = {
    swarselsystems.enabledHomeModules = [ "direnv" ];
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
}
