# desktop-style-stylix: darwin + homeDarwin wallpaper
# Wallpaper: den kept two named fetchurls, active = wallpaperaccess-17036190
# (other: wallhaven-qrd6xd https://w.wallhaven.cc/full/qr/wallhaven-qrd6xd.png sha256-ZS/ALvkETellw2squBX7bRmx1VURGQ9SAvQIjTuP9FI=)
{ inputs, ... }:
{
  ren.aspects.desktop-style-stylix = {
    darwin =
      { pkgs, ... }:
      {
        imports = [ inputs.stylix.darwinModules.stylix ];

        stylix = {
          base16Scheme = "${inputs.base16-schemes}/base16/tokyo-night-moon.yaml";

          enable = true;
          enableReleaseChecks = false;
          autoEnable = true;

          # home-manager stylix is configured separately (homeManager block).
          homeManagerIntegration.autoImport = false;
          homeManagerIntegration.followSystem = false;

          image = pkgs.fetchurl {
            url = "https://wallpaperaccess.com/full/17036190.jpg";
            hash = "sha256-D2lCIxuEbm3tsvZZoJ8C56/SmWiuCBafJ7UZ9jztng4=";
          };

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
              name = "DejaVuSansM Nerd Font Mono";
              package = pkgs.nerd-fonts.dejavu-sans-mono;
            };
            emoji = {
              name = "Noto Color Emoji";
              package = pkgs.noto-fonts-color-emoji;
            };
          };
        };
      };

    # stylix has no macOS wallpaper target, so apply the themed image with
    # desktoppr (reliable on current macOS) on each activation.
    homeDarwin =
      { config, pkgs, ... }:
      {
        home.activation.setWallpaper = config.lib.dag.entryAfter [ "writeBoundary" ] ''
          run ${pkgs.desktoppr}/bin/desktoppr "${config.stylix.image}" || true
        '';
      };
  };
}
