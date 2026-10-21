{ ... }:
{
  ren.aspects.app-media-qbittorrent = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.qbittorrent ];
      };
  };
}
