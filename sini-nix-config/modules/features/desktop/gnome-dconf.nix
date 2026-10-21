# desktop-gnome (dconf part): shell, mutter, wm, extensions
{ ... }:
{
  ren.aspects.desktop-gnome.homeManager =
    { lib, ... }:
    {
      dconf.settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";

        "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";

        "org/gnome/settings-daemon/plugins/power" = {
          power-button-action = "interactive";
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-ac-timeout = 1200;
        };

        "org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 900;

        # merged: den source declared "org/gnome/shell" twice (favorite-apps + extensions)
        "org/gnome/shell" = {
          favorite-apps = [
            "firefox.desktop"
            "kitty.desktop"
            "steam.desktop"
            "org.gnome.Nautilus.desktop"
          ];
          disable-user-extensions = false;
          enabled-extensions = [
            "pip-on-top@rafostar.github.com"
            "appindicatorsupport@rgcjonas.gmail.com"
            "gamemodeshellextension@trsnaqe.com"
          ];
        };

        "org/gnome/desktop/ally/applications"."screen-reader-enabled" = false;

        "org/gnome/mutter" = {
          center-new-windows = true;
          dynamic-workspaces = true;
          edge-tiling = true;
          experimental-features = [ "scale-monitor-framebuffer" ];
          workspaces-only-on-primary = true;
        };

        "org/gnome/shell/app-switcher".current-workspace-only = true;

        "org/gnome/desktop/wm/preferences" = {
          resize-with-right-button = true;
          action-middle-click-titlebar = "toggle-maximize-vertically";
          button-layout = "appmenu:minimize,maximize,close";
          focus-mode = "sloppy";
          dynamic-workspaces = false;
          num-workspaces = 10;
        };

        "org/gtk/gtk4/settings/file-chooser" = {
          show-hidden = true;
          sort-directories-first = true;
          view-type = "list";
        };

        "org/gnome/shell/extensions/pip-on-top".stick = true;

        "org/gnome/shell/extensions/gamemodeshellextension".show-icon-only-when-active = true;

        "org/gnome/settings-daemon/plugins/color" = {
          night-light-enabled = false;
          night-light-schedule-automatic = false;
        };

        "org/gnome/TextEditor".keybindings = "vim";
      };
    };
}
