# fonts: system font packages (headless hosts skip them)
{ ren, ... }:
{
  ren.aspects.fonts.nixos =
    { pkgs, ... }:
    {
      fonts = {
        enableDefaultPackages = true;
        packages = with pkgs; [
          dejavu_fonts
          font-awesome
          # inconsolata
          powerline-fonts
          source-code-pro
          # victor-mono
          # The nerd-fonts are several hundred MiB of glyphs that nothing on a headless machine ever rasterises (no X, no fontconfig consumer, no terminal attached).
          nerd-fonts.droid-sans-mono
          nerd-fonts.fantasque-sans-mono
          nerd-fonts.fira-code
          nerd-fonts.jetbrains-mono
          nerd-fonts.liberation # no mono version of this?
          nerd-fonts.ubuntu-mono
          nerd-fonts.symbols-only
        ];
      };
    };
}
