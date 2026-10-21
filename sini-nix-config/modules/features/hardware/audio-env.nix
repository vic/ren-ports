{ ... }:
{
  # Second file of hardware-audio: plugin search paths and audio packages.
  ren.aspects.hardware-audio.nixos =
    { pkgs, lib, ... }:
    let
      makePluginPath =
        format:
        "$HOME/.${format}:"
        + (lib.makeSearchPath format [
          "$HOME/.nix-profile/lib"
          "/run/current-system/sw/lib"
          "/etc/profiles/per-user/$USER/lib"
        ]);
    in
    {
      environment.sessionVariables = {
        ALSOFT_DRIVERS = "pulse";

        DSSI_PATH = makePluginPath "dssi";
        LADSPA_PATH = makePluginPath "ladspa";
        LV2_PATH = makePluginPath "lv2";
        LXVST_PATH = makePluginPath "lxvst";
        VST_PATH = makePluginPath "vst";
        VST3_PATH = makePluginPath "vst3";
      };

      environment.systemPackages = [
        pkgs.alsa-utils
        pkgs.playerctl
        pkgs.pavucontrol
        pkgs.pwvucontrol
        pkgs.paprefs
        pkgs.pulsemixer
        pkgs.cava
        pkgs.coppwr
        pkgs.qpwgraph
        pkgs.openal
        pkgs.pulseaudio
        pkgs.yabridge
        pkgs.yabridgectl
        pkgs.vital
        pkgs.odin2
        pkgs.fire
        pkgs.decent-sampler
        pkgs.lsp-plugins
      ];
    };
}
