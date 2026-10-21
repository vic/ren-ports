# desktop-hyprland: XDG mime associations
{ ... }:
{
  ren.aspects.desktop-hyprland.homeManager =
    { config, ... }:
    let
      editorApps = [ "nvim.desktop" ];
      browser = [ "firefox.desktop" ];
      imageViewer = [ "org.gnome.Loupe.desktop" ];
      pdfViewer = [ "org.pwmt.zathura.desktop" ];
      associations = {
        "text/x-dbus-service" = editorApps;
        "image/jpeg" = imageViewer;
        "image/png" = imageViewer;
        "image/gif" = imageViewer;
        "image/webp" = imageViewer;
        "image/tiff" = imageViewer;
        "image/x-tga" = imageViewer;
        "image/vnd-ms.dds" = imageViewer;
        "image/x-dds" = imageViewer;
        "image/bmp" = imageViewer;
        "image/vnd.microsoft.icon" = imageViewer;
        "image/vnd.radiance" = imageViewer;
        "image/x-exr" = imageViewer;
        "image/x-portable-bitmap" = imageViewer;
        "image/x-portable-graymap" = imageViewer;
        "image/x-portable-pixmap" = imageViewer;
        "image/x-portable-anymap" = imageViewer;
        "image/x-qoi" = imageViewer;
        "image/svg+xml" = imageViewer;
        "image/svg+xml-compressed" = imageViewer;
        "image/avif" = imageViewer;
        "image/heic" = imageViewer;
        "image/jxl" = imageViewer;
        "application/pdf" = pdfViewer;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/chrome" = browser;
        "text/html" = browser;
        "application/x-extension-htm" = browser;
        "application/x-extension-html" = browser;
        "application/x-extension-shtml" = browser;
        "application/xhtml+xml" = browser;
        "application/x-extension-xhtml" = browser;
        "application/x-extension-xht" = browser;
      };
    in
    {
      xdg = {
        configFile = {
          "mimeapps.list".force = true;
          "uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
        };
        mimeApps = {
          enable = true;
          defaultApplications = associations;
          associations.added = associations;
        };
      };
    };
}
