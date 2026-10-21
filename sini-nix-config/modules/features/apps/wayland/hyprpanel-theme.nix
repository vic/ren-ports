{ ... }:
{
  ren.aspects.app-wayland-hyprpanel.homeManager =
    {
      programs.hyprpanel.settings.theme = {
          font = {
            name = "DejaVuSansM Nerd Font Mono";
            size = "12px";
          };
          bar = {
            buttons = {
              modules.kbLayout.enableBorder = false;
              workspaces.enableBorder = false;
            };
            floating = false;
          };
          notification.enableShadow = false;
          osd = {
            active_monitor = true;
            duration = 1000;
            location = "bottom";
            margins = "0px 0px 35px 0px";
            muted_zero = true;
            orientation = "horizontal";
          };
      };
    };
}
