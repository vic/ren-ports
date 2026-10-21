# desktop-hyprland: media/resize/brightness keybinds
{ ... }:
{
  ren.aspects.desktop-hyprland.homeManager =
    { pkgs, ... }:
    let
      brightnessctlBin = "${pkgs.brightnessctl}/bin/brightnessctl";
      playerctlBin = "${pkgs.playerctl}/bin/playerctl";
      wpctl = "${pkgs.wireplumber}/bin/wpctl";

      PRIMARY = "SUPER";
      SECONDARY = "SHIFT";
      TERTIARY = "CTRL";
    in
    {
      wayland.windowManager.hyprland.settings = {
        # Keybinds - lock (media keys)
        bindl = [
          ", xf86AudioLowerVolume, exec, ${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%- && ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ 0"
          ", xf86AudioRaiseVolume, exec, ${wpctl} set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ 0"
          ", xf86AudioMute, exec, ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioPlay, exec, ${playerctlBin} play-pause"
          ", XF86AudioPause, exec, ${playerctlBin} play-pause"
          ", XF86AudioPrev, exec, ${playerctlBin} previous"
          ", XF86AudioNext, exec, ${playerctlBin} next"
          "${TERTIARY} ${SECONDARY}, N, exec, ${playerctlBin} next"
          "${TERTIARY} ${SECONDARY}, P, exec, ${playerctlBin} previous"
          "${TERTIARY} ${SECONDARY}, SPACE, exec, ${playerctlBin} play-pause"
        ];

        # Keybinds - repeat (resize)
        binde = [
          "${PRIMARY} ${SECONDARY}, left, resizeactive,-50 0"
          "${PRIMARY} ${SECONDARY}, right, resizeactive,50 0"
          "${PRIMARY} ${SECONDARY}, up, resizeactive,0 -50"
          "${PRIMARY} ${SECONDARY}, down, resizeactive,0 50"
        ];

        # Keybinds - lock + repeat (brightness)
        bindle = [
          ", xf86MonBrightnessDown, exec, ${brightnessctlBin} set 5%- -q"
          ", xf86MonBrightnessUp, exec, ${brightnessctlBin} set 5%+ -q"
        ];
      };
    };
}
