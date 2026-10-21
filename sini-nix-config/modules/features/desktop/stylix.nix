# desktop-style-stylix: nixos stylix + colord persist (darwin/hm in stylix-hm.nix)
{ inputs, ... }:
{
  ren.aspects.desktop-style-stylix = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.stylix.nixosModules.stylix ];

        config = {
          programs.dconf.enable = true;

          stylix = {
            base16Scheme = "${inputs.base16-schemes}/base16/tokyo-night-moon.yaml";

            enable = true;
            enableReleaseChecks = false;
            autoEnable = false;

            homeManagerIntegration.autoImport = false;
            homeManagerIntegration.followSystem = false;

            image = pkgs.nixos-artwork.wallpapers.stripes-logo.gnomeFilePath;

            polarity = "dark";

            fonts = {
              sizes = {
                terminal = 12;
                applications = 12;
                popups = 12;
              };
              serif = {
                name = "Source Serif";
                package = pkgs.source-serif;
              };
              sansSerif = {
                name = "Noto Sans";
                package = pkgs.noto-fonts;
              };
              monospace = {
                package = pkgs.nerd-fonts.dejavu-sans-mono;
                name = "DejaVu Sans Mono";
              };
              emoji = {
                package = pkgs.noto-fonts-color-emoji;
                name = "Noto Color Emoji";
              };
            };
          };
        };
      };

    persist.directories = [
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "0755";
      }
    ];

    homeManagerModules = [ inputs.stylix.homeModules.stylix ];

    homeLinux =
      { pkgs, ... }:
      {
        stylix = {
          icons = {
            enable = true;
            package = pkgs.catppuccin-papirus-folders.override {
              flavor = "mocha";
              accent = "lavender";
            };
            dark = "Papirus-Dark";
          };

          cursor = {
            name = "catppuccin-mocha-peach-cursors";
            size = 32;
            package = pkgs.catppuccin-cursors.mochaPeach;
          };
        };
      };
  };
}
