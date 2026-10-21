# desktop-flatpak: nix-flatpak system + hm, base repo and packages
{ ren, inputs, ... }:
{
  ren.aspects.desktop-flatpak.os =
    { pkgs, ... }:
    {
      imports = [
        inputs.omniflake.unified.nix-flatpak.nixosModules.nix-flatpak
      ];
      services.flatpak = {
        enable = true;
        remotes = [
          # { name = "flathub-beta"; location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo"; }
        ];
        packages = [
          # { appId = "com.example.Example"; origin = "flathub";  commit=<hash>}

          # Flatpak development and management.
          "org.flatpak.Builder"
          # Used to check/update manifest x-checker-data sources.
          "org.flathub.flatpak-external-data-checker"
          "com.github.tchx84.Flatseal"
          "io.github.flattool.Warehouse"
          "io.github.giantpinkrobots.flatsweep"
        ];
        update = {
          onActivation = true;
          auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };
        # overrides = { };
        # uninstallUnmanaged = true;
        uninstallUnused = true;
      };
      systemd.services.flatpak-repo = {
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.flatpak ];
        script = ''
          flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
      };
    };

  ren.aspects.desktop-flatpak.homeManager =
    { config, pkgs, ... }:
    {
      imports = [
        inputs.omniflake.unified.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      home.packages = with pkgs; [
        flatpak
      ];

      xdg.systemDirs.data = [
        "/var/lib/flatpak/exports/share"
        "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
      ];
    };
}
