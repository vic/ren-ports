# media: speechd/orca off; media-console (cli tools) and media-desktop (players) split out
{ ren, ... }:
{
  ren.aspects.media = {
    # Media

    os =
      { lib, ... }:
      {
        services.speechd.enable = lib.mkForce false;
        services.orca.enable = lib.mkForce false;
      };
  };

  ren.aspects.media-console = {
    # Media for a console environment.

    homeManager =
      { pkgs, ... }:
      {
        home.packages =
          (with pkgs; [
            ffmpeg-full
            yt-dlp
            mediainfo
            # exiftool
          ])
          ++ [
            (pkgs.callPackage ./_pinepods-firewood.nix { })
          ];
      };
  };

  ren.aspects.media-desktop = {
    # Media for a desktop environment.
    homeManager =
      { pkgs, ... }:
      {
        home.packages =
          (with pkgs; [
            mpv
            vlc

            tartube-yt-dlp

            nuclear
            shortwave
          ])
          ++ [
            (pkgs.callPackage ./_pinepods-desktop.nix { })
          ];

        services.easyeffects.enable = false;

        programs.freetube = {
          enable = true;
          #settings = {};
        };
      };
    includes = [
      ren.aspects.media-console
    ];
  };
}
