{ ... }:
{
  ren.aspects.app-wayland-waybar.homeManager =
    { config, lib, pkgs, ... }:
    {
      programs.waybar.settings.mainBar = {
          mpris = {
            dynamic-order = [
              "artist"
              "title"
              "album"
              "position"
              "length"
            ];
            format-paused = " 󰐊 ";
            format-playing = " 󰏤 ";
            format-stopped = " 󰓛 ";
          };

          tray = {
            icon-size = 24;
            spacing = 6;
            reverse-direction = true;
          };

          "wireplumber#sink" = {
            format = "{icon} {volume:03d}";
            max-volume = 150;
            on-click = "'${lib.getExe pkgs.pwvucontrol}'";
            node-type = "Audio/Sink";
            tooltip = true;
            tooltip-format = "{node_name}: {volume}%";
          };
          "wireplumber#source" = {
            format = "{icon} {volume:03d}";
            max-volume = 150;
            on-click = "'${lib.getExe pkgs.pwvucontrol}'";
            node-type = "Audio/Source";
            tooltip = true;
            tooltip-format = "{node_name}: {volume}%";
          };
          network = {
            interface = lib.mkDefault "br*";
            format-wifi = lib.mkDefault " {bandwidthDownOctets:>}  {bandwidthUpOctets:>} {essid} ({signalStrength}%) ";
            format-ethernet = lib.mkDefault " {bandwidthDownOctets:>}  {bandwidthUpOctets:>} {ipaddr}/{cidr} ";
            tooltip-format = lib.mkDefault "{ifname} via {gwaddr} ";
            format-linked = lib.mkDefault "{ifname} (No IP) 󰲛";
            format-disconnected = lib.mkDefault "";
            format-alt = lib.mkDefault "{ifname}: {ipaddr}/{cidr}";
            interval = 1;
          };
          "network#wifi" = {
            interface = lib.mkDefault "wlan*";
            format-wifi = lib.mkDefault " {bandwidthDownOctets:>}  {bandwidthUpOctets:>} {essid} ({signalStrength}%) ";
            format-ethernet = lib.mkDefault " {bandwidthDownOctets:>}  {bandwidthUpOctets:>} {ipaddr}/{cidr} ";
            tooltip-format = lib.mkDefault "{ifname} via {gwaddr} ";
            format-linked = lib.mkDefault "{ifname} (No IP) ";
            format-disconnected = lib.mkDefault "";
            format-alt = lib.mkDefault "{ifname}: {ipaddr}/{cidr}";
            interval = 1;
          };
      };

      programs.waybar.style = lib.mkAfter ''
          * {
            font-family: ${config.stylix.fonts.serif.name}, sans-serif;
          }

          #workspaces button {
            padding: 0px;
            border-bottom: 0px none transparent;
          }

          #niri-workspaces.empty,
          #hyprland-workspaces.empty {
            padding: 0;
            margin: 0;
            border: none;
            background: none;
            min-width: 0;
          }

          #custom-notification {
            font-size: 20px;
            font-weight: bolder;
            padding-left: 20px;
            padding-right: 24px;
          }
      '';
    };
}
