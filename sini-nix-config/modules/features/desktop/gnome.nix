# desktop-gnome: GNOME shell, extensions, gtk dark (dconf in gnome-dconf/gnome-keys)
{ ... }:
{
  ren.aspects.desktop-gnome = {
    nixos =
      { pkgs, lib, ... }:
      {
        environment = {
          systemPackages = [
            pkgs.gnome-tweaks
            pkgs.dconf-editor
            pkgs.gnomeExtensions.pop-shell
            pkgs.gnomeExtensions.appindicator
            pkgs.gnomeExtensions.pip-on-top
            pkgs.gnomeExtensions.gamemode-shell-extension
          ];
          gnome.excludePackages = [
            pkgs.epiphany
            pkgs.geary
            pkgs.gnome-font-viewer
            pkgs.gnome-maps
            pkgs.gnome-system-monitor
            pkgs.gnome-tour
          ];
        };

        services = {
          desktopManager.gnome.enable = true;
          udev.packages = [ pkgs.gnome-settings-daemon ];
        };

        programs.nautilus-open-any-terminal = {
          enable = true;
          terminal = "kitty";
        };

        # Avoid auto-starting orca in non-GNOME WMs
        systemd.user.services.orca.wantedBy = lib.mkForce [ ];
      };

    persist.directories = [ "/var/lib/AccountsService" ];

    homeManager.gtk = {
      enable = true;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
    };
  };
}
