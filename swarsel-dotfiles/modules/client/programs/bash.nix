{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.bash.homeManager =
    {
      osConfig ? null,
      config,
      lib,
      ...
    }:
    {
      config = {
        swarselsystems.enabledHomeModules = [ "bash" ];
        programs.bash = {
          enable = true;
          # needed for remote builders
          bashrcExtra = lib.mkIf (osConfig == null) ''
            export PATH="/nix/var/nix/profiles/default/bin:$PATH"
          '';
          historyControl = [
            "ignoreboth"
          ];
          historyFile = "${config.home.homeDirectory}/.histfile";
          historyFileSize = 100000;
          historySize = 100000;
        };
      };
    };
}
