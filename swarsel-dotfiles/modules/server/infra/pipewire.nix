{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.server-pipewire.nixos =
    {
      globals-defs,
      host,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
    in
    {
      config = {

        swarselsystems.enabledServerModules = [ "pipewire" ];
        users.persistentIds.rtkit = confLib.mkIds 996;
        services.pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          audio.enable = true;
          jack.enable = true;
          pulse.enable = true;
          wireplumber.enable = true;
        };
        environment.persistence."/state" = lib.mkIf config.swarselsystems.isMicroVM {
          directories = [
            {
              directory = "/var/lib/pipewire";
              group = "pipewire";
              user = "pipewire";
            }
          ];
        };
        security.rtkit.enable = true; # this is required for pipewire real-time access
      };
      key = "swarsel/server/server-pipewire";

    }

  ;
}
