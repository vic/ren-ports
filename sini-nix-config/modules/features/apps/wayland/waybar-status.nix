{ ... }:
{
  ren.aspects.app-wayland-waybar.homeManager =
    {
      programs.waybar.settings.mainBar = {
          "custom/notification" = {
            tooltip = false;
            format = "{icon}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
              inhibited-notification = "<span foreground='red'><sup></sup></span>";
              inhibited-none = "";
              dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
              dnd-inhibited-none = "";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "swaync-client -t";
            escape = true;
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };

          "group/indicators" = {
            modules = [
              "memory"
              "cpu"
            ];
            orientation = "inherit";
          };

          "cpu" = {
            "format" = "{icon}";
            "tooltip-format" = "{usage:3}%";
            "format-icons" = [
              ""
              "<span color='#6d9'></span>"
              "<span color='#fd2'></span>"
              "<span color='#f94'></span>"
              "<span color='#f55'></span>"
            ];
            "interval" = 2;
          };

          "memory" = {
            "format" = "{icon}";
            "tooltip-format" = ''
              Total: {total:.1f} GiB
              Total swap: {swapTotal:.1f} GiB

              Used: {used:.1f} GiB
              Used swap: {swapUsed:.1f} GiB

              Free: {avail:.1f} GiB
              Free swap: {swapAvail:.1f} GiB'';
            "format-icons" = [
              ""
              ""
              ""
              ""
              ""
              ""
              ""
              "<span color='#fd2'></span>"
              "<span color='#f94'></span>"
              "<span color='#f55'></span>"
            ];
            "interval" = 5;
          };
      };
    };
}
