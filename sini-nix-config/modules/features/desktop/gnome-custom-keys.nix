# desktop-gnome (custom media-key commands)
{ ... }:
{
  ren.aspects.desktop-gnome.homeManager =
    { pkgs, ... }:
    {
      dconf.settings = {
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Super>Return";
          command = "kitty";
          name = "kitty";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          binding = "<Shift><Super>h";
          command = "kitty -e htop";
          name = "htop";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
          binding = "<Shift><Super>s";
          command = "kitty -o term=xterm-kitty -e spotify_player";
          name = "spotify-player";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
          binding = "<Super>e";
          command = "kitty -e yazi";
          name = "File Manager";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
          binding = "<Shift><Super>n";
          command = "kitty -e nvtop";
          name = "nvtop";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
          binding = "<Super>Print";
          command = "${pkgs.bash}/bin/bash -c '${pkgs.wl-clipboard}/bin/wl-paste | ${pkgs.swappy}/bin/swappy -f -'";
          name = "Edit clipboard image";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
          binding = "<Super><Shift>Return";
          command = "kitty -e vim";
          name = "vim";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7" = {
          binding = "<Super><Shift>B";
          command = "firefox --new-window";
          name = "Firefox new window";
        };
      };
    };
}
