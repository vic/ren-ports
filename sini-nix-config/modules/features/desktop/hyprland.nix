# desktop-hyprland: system side + hm services (settings/binds/mime in hyprland-*.nix)
{ inputs, ... }:
{
  ren.aspects.desktop-hyprland = {
    nixos =
      { pkgs, lib, ... }:
      {
        environment.systemPackages = [
          pkgs.xwayland-satellite
          pkgs.wlogout
          pkgs.swaylock
        ];
        nix.settings = {
          substituters = [ "https://hyprland.cachix.org" ];
          trusted-substituters = [ "https://hyprland.cachix.org" ];
          trusted-public-keys = [
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          ];
        };

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
          GSK_RENDERER = "cairo";
        };

        programs.hyprland = {
          enable = true;
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
          withUWSM = true;
          xwayland.enable = true;
        };

        systemd.user.services.hyprpolkitagent = {
          path = lib.mkForce [ ];
          serviceConfig.Slice = "session-graphical.slice";
          wantedBy = [ "graphical-session.target" ];
        };

        services = {
          dbus = {
            implementation = "broker";
            packages = [
              pkgs.gcr
              pkgs.gnome-settings-daemon
            ];
          };

          gnome.gnome-keyring.enable = true;
          gnome.sushi.enable = true;
          devmon.enable = true;
          gvfs.enable = true;
          udisks2.enable = true;
        };
      };

    homeManagerModules = [ inputs.hyprland.homeManagerModules.default ];

    homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [
          pkgs.hyprpicker
          pkgs.hyprcursor
          pkgs.libnotify
          pkgs.networkmanagerapplet
          pkgs.blueman
          pkgs.pwvucontrol
          pkgs.snapshot
        ];

        programs = {
          wofi.enable = true;
          rofi.enable = true;
        };

        systemd.user.services.hyprpolkitagent.Unit.ConditionEnvironment = lib.mkForce [
          "|XDG_CURRENT_DESKTOP=Hyprland"
          "|XDG_CURRENT_DESKTOP=niri"
        ];

        systemd.user.services.hyprpaper = {
          Unit.ConditionEnvironment = lib.mkForce [
            "|XDG_CURRENT_DESKTOP=Hyprland"
            "|XDG_CURRENT_DESKTOP=niri"
          ];
          Service.Slice = "background-graphical.slice";
        };

        services.hyprpaper = {
          enable = true;
          settings = {
            ipc = "on";
            splash = false;
          };
        };
      };
  };
}
