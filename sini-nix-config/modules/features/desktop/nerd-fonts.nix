# desktop-style-fonts-nerd-fonts
{ ... }:
{
  ren.aspects.desktop-style-fonts-nerd-fonts.nixos =
    { pkgs, ... }:
    {
      fonts.packages = [
        pkgs.nerd-fonts.symbols-only
        pkgs.nerd-fonts.adwaita-mono
        pkgs.nerd-fonts.dejavu-sans-mono
        pkgs.nerd-fonts.fira-mono
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.nerd-fonts.meslo-lg
        pkgs.nerd-fonts.ubuntu-mono
        pkgs.nerd-fonts.terminess-ttf
      ];
    };
}
