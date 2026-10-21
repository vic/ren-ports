{ ren, ... }:
{
  ren.aspects.media = {
    includes = with ren.aspects; [
      app-media-jellyfin-client
      app-media-mpv
      app-media-spicetify
      app-media-qbittorrent
      app-media-youtube-music
      app-media-yt-dlp
    ];
  };
}
