{ ren, ... }:
{
  ren.aspects.app-wayland-waybar.homeManager =
    {
      is,
      host,
      lib,
      ...
    }:
    {
      systemd.user.services.waybar = {
        Unit.ConditionEnvironment = lib.mkForce [
          "|XDG_CURRENT_DESKTOP=Hyprland"
          "|XDG_CURRENT_DESKTOP=niri"
          "WAYLAND_DISPLAY"
        ];
        Service.Slice = "background-graphical.slice";
      };
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        systemd.targets = [ "graphical-session.target" ];
      };

      programs.waybar.settings.mainBar = {
          name = "main";
          id = "main";
          layer = "top";
          position = "top";
          exclusive = true;
          fixed-center = true;
          gtk-layer-shell = true;
          margin-top = 7;
          margin-left = 7;
          margin-right = 7;
          margin-bottom = 0;

          height = 32;
          spacing = 8;

          modules-left = [
            "niri/workspaces"
            "hyprland/workspaces"
            "hyprland/submap"
          ];

          modules-center = [
            "hyprland/window"
            "niri/window"
          ];

          modules-right = [
            "network"
            "network#wifi"
            "idle_inhibitor"
            "wireplumber#sink"
            "wireplumber#source"
            "cpu"
          ]
          ++ lib.optional (is ren.aspects.hardware-laptop host) "battery"
          ++ [
            "mpris"
            "tray"
            "clock"
            "custom/notification"
          ];
      };
    };
}
