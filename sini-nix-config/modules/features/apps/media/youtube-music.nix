{ ... }:
{
  ren.aspects.app-media-youtube-music = {
    homeManager = { ... }: {
      home.packages = [
        #pkgs.ytmdesktop # TODO: re-enable
      ];
    };
  };
}
