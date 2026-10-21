# desktop-style-stylix: homeManager stylix (same wallpaper as darwin)
{ inputs, ... }:
{
  ren.aspects.desktop-style-stylix = {
    homeManager =
      { pkgs, stylix-hm, lib, ... }:
      {
        stylix = lib.mkMerge (
          stylix-hm
          ++ [
            {
              base16Scheme = "${inputs.base16-schemes}/base16/tokyo-night-moon.yaml";

              enable = true;
              enableReleaseChecks = false;
              autoEnable = false;

              image = pkgs.fetchurl {
                url = "https://wallpaperaccess.com/full/17036190.jpg";
                hash = "sha256-D2lCIxuEbm3tsvZZoJ8C56/SmWiuCBafJ7UZ9jztng4=";
              };

              polarity = "dark";

              targets.qt.enable = false;

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
                  name = "DejaVuSansM Nerd Font Mono";
                };
                emoji = {
                  package = pkgs.noto-fonts-color-emoji;
                  name = "Noto Color Emoji";
                };
              };
            }
          ]
        );
      };
  };
}
