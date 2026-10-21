{ ... }:
{
  ren.aspects.app-shell-disk.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.dust
        pkgs.dua
        pkgs.dysk
        pkgs.ncdu
      ];
    };
}
