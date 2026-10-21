{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.pulseaudio.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config.services.pulseaudio = {
        enable = lib.mkIf (!config.services.pipewire.enable) true;
        package = pkgs.pulseaudioFull;
      };
    };
}
