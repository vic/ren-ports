{ ... }:
{
  ren.aspects.app-wayland-swaync.homeManager =
    {
      services.swaync.style = ''
            .notification,
            .notification.low,
            .notification.normal,
            .notification.critical,
            .notification-default-action,
            .notification-default-action:hover,
            .notification-default-action:active,
            .notification-row:focus,
            .notification-group:focus,
            .notification-group.collapsed .notification-row .notification,
            .control-center .notification-row .notification-background,
            .control-center .notification-row .notification-background:hover,
            .control-center .notification-row .notification-background:active {
              background: transparent;
              border: none;
              outline: none;
              box-shadow: none;
              margin: 0;
              padding: 0;
            }

            .control-center {
              background: @base00;
              border: 1px solid @base0D;
              color: @base05;
              padding: 5px;
              border-radius: 15px;
            }

            .widget-body, .widget-mpris, .widget-dnd, .widget-inhibitors {
              margin: 4px 5px;
            }

            .notification-content {
              border-radius: 12px;
              padding: 10px;
              margin: 8px;
            }

            .notification-title {
              font-weight: bold;
              color: @base05;
            }

            .close-button {
              margin: 6px;
              padding: 3px;
              border-radius: 100px;
              background-color: transparent;
              border: 1px solid transparent;
            }

            .close-button:hover {
              background-color: @base0C;
            }

            .close-button:active {
              background-color: @base0C;
              color: @base00;
            }
      '';
    };
}
