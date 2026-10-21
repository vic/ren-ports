# Chromium on Linux: native nixpkgs build via programs.chromium. Same aspect as chromium.nix.
{ ... }:
{
  ren.aspects.app-browsers-chromium.homeLinux =
    { lib, pkgs, ... }:
    let
      inherit (lib.strings) concatStringsSep enableFeature;
      features = import ./_chromium-features.nix;
    in
    {
      programs.chromium = {
        enable = true;

        package = pkgs.chromium.override {
          enableWideVine = true;
        };

        extensions = import ./_chromium-extensions.nix;

        commandLineArgs = [
          # Wayland
          "--ozone-platform=wayland"

          # GPU acceleration is left to Chromium's own driver detection. The
          # force-on switches (--ignore-gpu-blocklist, --enable-gpu-rasterization,
          # --enable-zero-copy) have no firefox analogue: firefox honours its own
          # graphics blocklist even with gfx.webrender.all, and zero-copy
          # rasterization corrupts page tiles on mesa. Hardware video decode is
          # requested through the Vaapi* features above, which is the part
          # media.ffmpeg.vaapi.enabled actually mirrors.

          # Quality of life
          "--no-first-run"
          "--no-default-browser-check"

          # Crash reporting (mirrors browser.tabs.crashReporting.sendReport = false)
          "--disable-breakpad"
          "--no-crash-upload"

          # Privacy / telemetry
          "--no-pings"
          "--no-service-autorun"
          "--disable-sync"
          "--component-updater=require_encryption"
          (enableFeature false "speech-api")
          (enableFeature false "speech-synthesis-api")

          # Extension hardening — only Web Store-signed extensions load
          "--extension-content-verification=enforce_strict"
          "--extensions-install-verification=enforce_strict"
        ]
        ++ [
          "--enable-features=${concatStringsSep "," features.enabled}"
          "--disable-features=${concatStringsSep "," features.disabled}"
        ];
      };

      xdg.mimeApps.defaultApplications = {
        "text/html" = [ "chromium-browser.desktop" ];
        "text/xml" = [ "chromium-browser.desktop" ];
        "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
        "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
      };
    };
}
