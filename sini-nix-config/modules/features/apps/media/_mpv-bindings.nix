# mpv key bindings and script options.
{
  bindings = {
    "MOUSE_BTN2" = "script-binding uosc/menu-blurred";
    "tab" = "script-binding uosc/toggle-ui";
    "Shift+ENTER" = "script-binding uosc/download-subtitles";
    a = "cycle audio";
    s = "cycle sub";
    WHEEL_UP = "add volume 2.5";
    WHEEL_DOWN = "add volume -2.5";
    UP = "add volume 2.5";
    DOWN = "add volume -2.5";
    ENTER = "ignore";
    "=" = "add video-zoom 0.1";
    "-" = "add video-zoom -0.1";
    "alt+=" = "add video-rotate 90";
    "alt+-" = "add video-rotate -90";
  };

  scriptOpts = {
    uosc = {
      controls = "subtitles,<has_chapter>chapters,<has_many_audio>audio,<has_many_video>video,<has_many_edition>editions,<stream>stream-quality,space,menu";
    };
    autoload = {
      disabled = false;
      images = false;
      videos = true;
      audio = true;
      ignore_hidden = true;
      same_type = true;
      directory_mode = "ignore";
    };
  };
}
