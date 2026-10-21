# media-books: calibre + z-library
{ ren, ... }:
{
  ren.aspects.media-books.homeManager = { pkgs, ... }: {
    home.packages = with pkgs; [
      z-library-desktop
    ];

    programs.calibre = {
      enable = true;
    };
  };
}
