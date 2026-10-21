{ ... }:
{
  ren.aspects.app-wayland-waybar.homeManager =
    {
      programs.waybar.settings.mainBar = {
          "niri/workspaces" = {
            format = "{value}";
            format-icons = {
              active = "";
              default = "";
            };
          };

          "niri/window" = {
            "icon" = true;
            "icon-size" = 16;
            "format" = " {title}";
            "on-scroll-down" = "niri msg action focus-column-right";
            "on-scroll-up" = "niri msg action focus-column-left";
          };

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              active = "";
              default = "";
              persistent = "";
            };
            on-scroll-up = "hyprctl dispatch workspace r-1";
            on-scroll-down = "hyprctl dispatch workspace r+1";
            all-outputs = false;
            persistent_workspaces = {
              "*" = 5;
            };
          };

          "hyprland/window" = {
            "icon" = true;
            "icon-size" = 24;
            "format" = " {title}";
          };

          battery = {
            format = "{icon}";
            "format-icons" = [
              ""
              ""
              ""
              ""
              ""
            ];
            states = {
              critical = 20;
            };
            tooltip-format = ''
              Capacity: {capacity}%
              {timeTo}
              Draw: {power} watts.'';
          };

          clock = {
            format = "{:%a %e %b  %I:%M %p}";
            interval = 1;
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            "calendar" = {
              "weeks-pos" = "left";
              "format" = {
                "months" = "<span color='#eee'>{}</span>";
                "days" = "<span color='#eee'>{}</span>";
                "weeks" = "<span color='#888'>{}</span>";
                "today" = "<span color='#eee'><b><u>{}</u></b></span>";
              };
            };
            "actions" = {
              "on-scroll-up" = "shift_up";
              "on-scroll-down" = "shift_down";
            };
          };
      };
    };
}
