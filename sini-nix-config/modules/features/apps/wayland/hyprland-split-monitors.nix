{ ... }:
{
  ren.aspects.app-wayland-hyprland-split-monitors.homeManager =
    { pkgs, ... }:
    let
      PRIMARY = "SUPER";
      SECONDARY = "SHIFT";
      TERTIARY = "CTRL";
    in
    {
      home.packages = [ pkgs.split-monitor-workspaces ];

      wayland.windowManager.hyprland = {
        plugins = [ pkgs.split-monitor-workspaces ];

        settings = {
          plugin.split-monitor-workspaces = {
            count = 5;
            keep_focused = false;
            enable_notifications = false;
            enable_persistent_workspaces = 1;
            enable_wrapping = false;
          };

          bind = [
            "${PRIMARY}, page_up, split-workspace, m-1"
            "${PRIMARY}, page_down, split-workspace, m+1"
            "${PRIMARY}, bracketleft, split-workspace, -1"
            "${PRIMARY}, bracketright, split-workspace, +1"
            "${PRIMARY}, mouse_up, split-workspace, m+1"
            "${PRIMARY}, mouse_down, split-workspace, m-1"
            "${PRIMARY} ${SECONDARY}, U, movetoworkspace, special"
            "${PRIMARY}, U, togglespecialworkspace,"
            "${PRIMARY} ${TERTIARY}, page_up, split-movetoworkspace, -1"
            "${PRIMARY} ${TERTIARY}, page_down, split-movetoworkspace, +1"
            "${PRIMARY} ${SECONDARY}, page_up, split-movetoworkspacesilent, -1"
            "${PRIMARY} ${SECONDARY}, page_down, split-movetoworkspacesilent, +1"

            "${PRIMARY} ${TERTIARY}, left, split-changemonitor, prev"
            "${PRIMARY} ${TERTIARY}, right, split-changemonitor, next"
          ]
          ++ (builtins.concatLists (
            builtins.genList (x: [
              "${PRIMARY}, ${toString (x + 1)}, split-workspace, ${toString (x + 1)}"
              "${PRIMARY} ${TERTIARY}, ${toString (x + 1)}, split-movetoworkspace, ${toString (x + 1)}"
              "${PRIMARY} ${SECONDARY}, ${toString (x + 1)}, split-movetoworkspacesilent, ${toString (x + 1)}"
            ]) 5
          ));
        };
      };
    };
}
