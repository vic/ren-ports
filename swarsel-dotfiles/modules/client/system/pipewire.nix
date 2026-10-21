{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.pipewire.nixos =
    {
      globals-defs,
      host,
      config,
      pkgs,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
    in
    {
    config = {
      users.persistentIds.rtkit = confLib.mkIds 996;
      services.pipewire = {
        enable = true;
        package = pkgs.pipewire;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        audio.enable = true;
        jack.enable = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };
      security.rtkit.enable = true; # this is required for pipewire real-time access
    };
  };
}
