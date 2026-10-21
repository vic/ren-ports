{ ... }:
{
  ren.aspects.app-wayland-hyprpanel.homeManager =
    { config, pkgs, ... }:
    {
      programs.hyprpanel.settings.menus = {
          clock = {
            time = {
              military = true;
              hideSeconds = true;
            };
            weather.unit = "metric";
          };
          dashboard = {
            directories = {
              enabled = true;
              left = {
                directory1 = {
                  command = "${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi ${config.home.homeDirectory}/Downloads";
                  label = "󰉍 Downloads";
                };
                directory2 = {
                  command = "${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi ${config.home.homeDirectory}/Videos";
                  label = "󰉏 Videos";
                };
                directory3 = {
                  command = "${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi ${config.home.homeDirectory}/repos";
                  label = "󰚝 Projects";
                };
              };
              right = {
                directory1 = {
                  command = "${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi ${config.home.homeDirectory}/Documents";
                  label = "󱧶 Documents";
                };
                directory2 = {
                  command = "${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi ${config.home.homeDirectory}/Pictures";
                  label = "󰉏 Pictures";
                };
                directory3 = {
                  command = "${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi ${config.home.homeDirectory}";
                  label = "󱂵 Home";
                };
              };
            };
          };
          power = {
            lowBatteryNotification = true;
            lowBatteryNotificationText = "Battery is running low - $POWER_LEVEL %";
            lowBatteryThreshold = 15;
          };
      };
    };
}
