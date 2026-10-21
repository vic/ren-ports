# desktop-gnome (keybindings part): wm, shell, media-keys list
{ ... }:
{
  ren.aspects.desktop-gnome.homeManager = {
      dconf.settings = {
        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Super>q" ];
          move-to-workspace-1 = [ "<Shift><Super>1" ];
          move-to-workspace-2 = [ "<Shift><Super>2" ];
          move-to-workspace-3 = [ "<Shift><Super>3" ];
          move-to-workspace-4 = [ "<Shift><Super>4" ];
          move-to-workspace-5 = [ "<Shift><Super>5" ];
          move-to-workspace-6 = [ "<Shift><Super>6" ];
          move-to-workspace-7 = [ "<Shift><Super>7" ];
          move-to-workspace-8 = [ "<Shift><Super>8" ];
          move-to-workspace-9 = [ "<Shift><Super>9" ];
          move-to-workspace-10 = [ "<Shift><Super>0" ];
          switch-to-workspace-1 = [ "<Super>1" ];
          switch-to-workspace-2 = [ "<Super>2" ];
          switch-to-workspace-3 = [ "<Super>3" ];
          switch-to-workspace-4 = [ "<Super>4" ];
          switch-to-workspace-5 = [ "<Super>5" ];
          switch-to-workspace-6 = [ "<Super>6" ];
          switch-to-workspace-7 = [ "<Super>7" ];
          switch-to-workspace-8 = [ "<Super>8" ];
          switch-to-workspace-9 = [ "<Super>9" ];
          switch-to-workspace-10 = [ "<Super>10" ];
          toggle-fullscreen = [ "<Super>f" ];
        };

        "org/gnome/shell/keybindings" = {
          switch-to-application-1 = [ ];
          switch-to-application-2 = [ ];
          switch-to-application-3 = [ ];
          switch-to-application-4 = [ ];
          switch-to-application-5 = [ ];
          switch-to-application-6 = [ ];
          switch-to-application-7 = [ ];
          switch-to-application-8 = [ ];
          switch-to-application-9 = [ ];
        };

        "org/gnome/settings-daemon/plugins/media-keys" = {
          next = [ "<Shift><Control>n" ];
          previous = [ "<Shift><Control>p" ];
          play = [ "<Shift><Control>space" ];
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/"
          ];
        };
    };
  };
}
