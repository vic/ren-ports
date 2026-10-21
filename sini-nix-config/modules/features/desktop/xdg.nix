# desktop-xdg: xdg user dirs + xdg-utils
{ ... }:
{
  ren.aspects.desktop-xdg.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.xdg-utils ];

      xdg = {
        enable = true;
        userDirs.enable = true;
      };
    };
}
