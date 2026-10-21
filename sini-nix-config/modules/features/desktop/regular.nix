# desktop-style-fonts-regular: text/icon/emoji fonts (corefonts, vista-fonts are unfree)
{ ... }:
{
  ren.aspects.desktop-style-fonts-regular = {
    unfree = [
      "corefonts"
      "vista-fonts"
    ];

    nixos =
      { pkgs, ... }:
      {
        fonts.packages = [
          pkgs.adwaita-fonts
          pkgs.aporetic
          pkgs.atkinson-hyperlegible-next
          pkgs.corefonts
          pkgs.dejavu_fonts
          pkgs.dina-font
          pkgs.fira
          pkgs.font-awesome
          pkgs.googlesans-code
          pkgs.inter
          pkgs.jetbrains-mono
          pkgs.libertine
          pkgs.maple-mono.NF
          pkgs.material-icons
          pkgs.material-symbols
          pkgs.monaspace
          pkgs.montserrat
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.noto-fonts-cjk-serif
          pkgs.noto-fonts-color-emoji
          pkgs.openmoji-color
          pkgs.source-code-pro
          pkgs.twemoji-color-font
          pkgs.vista-fonts
          # Local font pkgs...
          pkgs.local.feather
          pkgs.local.sf-mono
          pkgs.local.sf-pro
        ];
      };
  };
}
