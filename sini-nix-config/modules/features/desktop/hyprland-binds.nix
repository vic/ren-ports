# desktop-hyprland: keybinds
{ ... }:
{
  ren.aspects.desktop-hyprland.homeManager =
    { pkgs, osConfig, ... }:
    let
      uwsm = "${pkgs.uwsm}/bin/uwsm";
      prefix = if osConfig.programs.hyprland.withUWSM then "${uwsm} app --" else "";
      term = "${prefix} kitty";
      editor = "nvim";

      hyprshotBin = "${pkgs.hyprshot}/bin/hyprshot";
      loginctl = "${pkgs.elogind}/bin/loginctl";
      swappyBin = "${pkgs.swappy}/bin/swappy";
      wl-paste = "${pkgs.wl-clipboard}/bin/wl-paste";

      PRIMARY = "SUPER";
      SECONDARY = "SHIFT";
      TERTIARY = "CTRL";
    in
    {
      wayland.windowManager.hyprland.settings = {
        # Keybinds - mouse
        bindm = [ "${PRIMARY}, mouse:272, movewindow" ];

        # Keybinds - main
        bind = [
          "ALT, Tab, cyclenext, next"
          "SUPER, Tab, focusmonitor, +1"
          "ALT SHIFT, Tab, cyclenext, prev"
          "SUPER SHIFT, Tab, focusmonitor, -1"

          # Apps
          "${PRIMARY}, Return, exec, ${term}"
          "${PRIMARY} ${SECONDARY}, Return, exec, ${term} -e ${editor}"
          "${PRIMARY}, Space, exec, ${pkgs.wofi}/bin/wofi --allow-images --show drun"
          "${PRIMARY}, E, exec, ${term} -e yazi"
          "${PRIMARY} ${SECONDARY}, H, exec, ${term} -e btop"
          "${PRIMARY} ${SECONDARY}, N, exec, ${term} -e nvtop"
          "${PRIMARY} ${SECONDARY}, S, exec, ${term} -o term=xterm-kitty --class spotify_player -e spotify_player"
          "${PRIMARY} ${SECONDARY}, B, exec, ${prefix} firefox --new-window"

          # Screenshots
          ", Print, exec, ${hyprshotBin} -m region --clipboard-only --freeze"
          "ALT, Print, exec, ${hyprshotBin} -m window --clipboard-only --freeze"
          "${SECONDARY}, Print, exec, ${hyprshotBin} -m output --clipboard-only --freeze"
          ", xf86Cut, exec, ${hyprshotBin} -m region --raw --freeze | ${swappyBin} -f -"
          "${PRIMARY}, Print, exec, ${wl-paste} | ${swappyBin} -f -"

          # Window management
          "${PRIMARY}, Q, killactive"
          "${PRIMARY}, F, fullscreen"
          "${PRIMARY} ${SECONDARY}, F, togglefloating"
          "${PRIMARY}, P, pseudo"
          "${PRIMARY}, S, togglesplit"
          "${PRIMARY} ${SECONDARY}, L, exec, ${loginctl}  lock-session"
          "${PRIMARY} ${SECONDARY}, C, exec, ${uwsm} stop"

          # Move focus
          "${PRIMARY}, h, movefocus, l"
          "${PRIMARY}, j, movefocus, d"
          "${PRIMARY}, k, movefocus, u"
          "${PRIMARY}, l, movefocus, r"
          "${PRIMARY}, left, movefocus, l"
          "${PRIMARY}, down, movefocus, d"
          "${PRIMARY}, up, movefocus, u"
          "${PRIMARY}, right, movefocus, r"

          # Move windows
          "${PRIMARY} ${TERTIARY}, h, movewindow, l"
          "${PRIMARY} ${TERTIARY}, j, movewindow, d"
          "${PRIMARY} ${TERTIARY}, k, movewindow, u"
          "${PRIMARY} ${TERTIARY}, l, movewindow, r"
          "${PRIMARY} ${TERTIARY}, left, movewindow, l"
          "${PRIMARY} ${TERTIARY}, down, movewindow, d"
          "${PRIMARY} ${TERTIARY}, up, movewindow, u"
          "${PRIMARY} ${TERTIARY}, right, movewindow, r"
          # (den source had split-monitor-workspaces binds commented out; dropped)
        ];
      };
    };
}
