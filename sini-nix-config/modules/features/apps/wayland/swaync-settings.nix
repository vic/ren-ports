{ ... }:
{
  ren.aspects.app-wayland-swaync.homeManager =
    { lib, ... }:
    {
      systemd.user.services.swaync = {
        Unit.ConditionEnvironment = lib.mkForce [
          "|XDG_CURRENT_DESKTOP=Hyprland"
          "|XDG_CURRENT_DESKTOP=niri"
        ];
        Service.Slice = "background-graphical.slice";
      };

      services.swaync.enable = true;
      services.swaync.settings = {
        control-center-layer = "top";
        control-center-width = 400;
        control-center-height = 400;
        control-center-margin-top = 10;
        control-center-margin-bottom = 250;
        control-center-margin-right = 10;

        notification-window-width = 380;
        notification-icon-size = 48;
        notification-body-image-height = 80;
        notification-body-image-width = 160;
        notification-2fa-action = true;
        notification-grouping = false;

        image-visibility = "when-available";
        transition-time = 100;

        widgets = [
          "title"
          "buttons-grid"
          "dnd"
          "inhibitors"
          "mpris"
          "notifications"
        ];

        widget-config = {
          inhibitors = {
            text = "Inhibitors";
            button-text = "Clear All";
            clear-all-button = true;
          };
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear All";
          };
          dnd = {
            text = "Do Not Disturb";
          };
          mpris = {
            image-size = 64;
            blur = true;
          };
        };
      };
    };
}
