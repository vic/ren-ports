{ ren, ... }:
{
  ren.aspects.app-wayland-hyprpanel.homeManager =
    {
      is,
      host,
      lib,
      pkgs,
      ...
    }:
    {
      programs.hyprpanel = {
        enable = true;
        systemd.enable = true;
        settings = {
          bar.layouts."0" = {
            left = [
              "dashboard"
              "workspaces"
            ];
            middle = [ "media" ];
            right = [
              "volume"
              "network"
              "bluetooth"
            ]
            ++ lib.optional (is ren.aspects.hardware-laptop host) "battery"
            ++ [
              "systray"
              "clock"
              "notifications"
            ];
          };
          launcher.autoDetectIcon = true;
          bluetooth = {
            label = true;
            rightClick = "${pkgs.blueman}/bin/blueman-manager";
          };
          network = {
            rightClick = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
            showWifiInfo = true;
          };
          notifications.show_total = false;
          windowtitle.custom_title = true;
          workspaces = {
            ignored = "-\\d+";
            monitorSpecific = true;
            show_icons = true;
            show_numbered = false;
            workspaceMask = false;
          };
        };
      };
    };
}
