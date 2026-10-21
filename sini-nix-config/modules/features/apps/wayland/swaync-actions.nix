{ ... }:
{
  ren.aspects.app-wayland-swaync.homeManager =
    { pkgs, ... }:
    {
      services.swaync.settings.widget-config.buttons-grid = {
          actions = [
            {
              label = "󰐥";
              command = "systemctl poweroff";
            }
            {
              label = "󰜉";
              command = "systemctl reboot";
            }
            {
              label = "󰒲";
              command = "systemctl suspend";
            }
            {
              label = "󰌾";
              command = "lock";
            }
            {
              label = "󰍃";
              command = "${pkgs.hyprland}/bin/hyprctl dispatch exit";
            }
            {
              label = "󰕾";
              command = "${pkgs.swayosd}/bin/swayosd-client --output-volume mute-toggle";
            }
            {
              label = "󰍬";
              command = "${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle";
            }
            {
              label = "󰂯";
              command = "${pkgs.blueman}/bin/blueman-manager";
            }
            {
              label = "󰹑";
              command = "screenshot region";
            }
            {
              label = "󰋱";
              command = "hyprfocus-toggle";
            }
          ];
      };
    };
}
