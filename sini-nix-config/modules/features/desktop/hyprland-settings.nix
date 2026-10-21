# desktop-hyprland: wayland.windowManager.hyprland base settings
{ ... }:
{
  ren.aspects.desktop-hyprland.homeManager.wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    xwayland.enable = true;

    settings = {
      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
      ];
      exec-once = [ "uwsm finalize" ];
      ecosystem.no_donation_nag = true;
      misc = {
        disable_hyprland_logo = true;
        focus_on_activate = true;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
      };
      xwayland.force_zero_scaling = true;

      # Input
      input = {
        follow_mouse = 1;
        accel_profile = "flat";
        kb_layout = "us";
        numlock_by_default = true;
        touchpad = {
          disable_while_typing = true;
          natural_scroll = "no";
          tap-to-click = true;
        };
        sensitivity = 0;
        scroll_factor = 1.0;
        emulate_discrete_scroll = 1;
        repeat_delay = 275;
        repeat_rate = 35;
      };

      # Tiling (dwindle)
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        special_scale_factor = 0.85;
        force_split = 2;
      };
      general.resize_on_border = true;

      # Animations
      animations = {
        enabled = "yes";
        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
          "linear, 0.0, 0.0, 1.0, 1.0"
          "wind, 0.05, 0.9, 0.1, 1.05"
          "winIn, 0.1, 1.1, 0.1, 1.1"
          "winOut, 0.3, -0.3, 0, 1"
          "slow, 0, 0.85, 0.3, 1"
          "overshot, 0.7, 0.6, 0.1, 1.1"
          "bounce, 1.1, 1.6, 0.1, 0.85"
          "sligshot, 1, -1, 0.15, 1.25"
          "nice, 0, 6.9, 0.5, -4.20"
        ];
        animation = [
          "windowsIn, 1, 2, slow, popin"
          "windowsOut, 1, 2, winOut, popin"
          "windowsMove, 1, 1, wind, slide"
          "border, 1, 1, linear"
          "fade, 1, 3, overshot"
          "workspaces, 1, 3, wind"
          "windows, 1, 3, bounce, popin"
        ];
      };

      # Split monitor workspaces plugin
      plugin.split-monitor-workspaces = {
        count = 5;
        keep_focused = false;
        enable_notifications = false;
        enable_persistent_workspaces = 1;
        enable_wrapping = false;
      };
    };
  };
}
