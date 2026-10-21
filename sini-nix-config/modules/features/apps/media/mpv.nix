# mpv. Profile tables, extraInput and MIME list live in _mpv-*.nix helpers.
{ ... }:
{
  ren.aspects.app-media-mpv.homeManager =
    { pkgs, ... }:
    let
      shaders = "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/";
      profiles =
        import ./_mpv-profiles-basic.nix shaders
        // import ./_mpv-profiles-anime-high.nix shaders
        // import ./_mpv-profiles-anime-fast.nix shaders;
    in
    {
      home.packages = [
        pkgs.vapoursynth-mvtools
      ];

      programs.mpv = {
        enable = true;

        config = {
          autofit = "70%";
          vo = "gpu-next";
          gpu-api = "vulkan";
          hwdec = "auto-safe";
          ao = "pipewire";
          alang = "jpn,jap,ja,jp,eng,en";
          sub-auto = "fuzzy";
          screenshot-directory = "~/Pictures";
          screenshot-template = "mpv-%f-%wH.%wM.%wS.%wT-#%#00n";
          ytdl-format = "bestvideo+bestaudio";
          slang = "eng,en";
          hwdec-codecs = "all";
        };

        inherit (import ./_mpv-bindings.nix) bindings scriptOpts;

        scripts = with pkgs.mpvScripts; [
          inhibit-gnome
          mpris
          autoload
          uosc
          thumbfast
          sponsorblock
          quality-menu
          autosubsync-mpv
          chapterskip
          evafast
          youtube-upnext
        ];

        extraInput = import ./_mpv-input.nix profiles;

        defaultProfiles = [ "high-quality" ];

        profiles = {
          fsr = profiles.fsr.settings;
          cas = profiles.cas.settings;
          fsr-cas = profiles.fsr-cas.settings;
          anime4k-high-a = profiles.anime4k-high-a.settings;
          anime4k-high-b = profiles.anime4k-high-b.settings;
          anime4k-high-c = profiles.anime4k-high-c.settings;
          anime4k-high-aa = profiles.anime4k-high-aa.settings;
          anime4k-high-bb = profiles.anime4k-high-bb.settings;
          anime4k-high-ca = profiles.anime4k-high-ca.settings;
          anime4k-fast-a = profiles.anime4k-fast-a.settings;
          anime4k-fast-b = profiles.anime4k-fast-b.settings;
          anime4k-fast-c = profiles.anime4k-fast-c.settings;
          anime4k-fast-aa = profiles.anime4k-fast-aa.settings;
          anime4k-fast-bb = profiles.anime4k-fast-bb.settings;
          anime4k-fast-cc = profiles.anime4k-fast-cc.settings;
          genreric = profiles.generic.settings;
          generic-high = profiles.generic-high.settings;
          nnedi-high = profiles.nnedi-high.settings;
          nnedi-very-high = profiles.nnedi-very-high.settings;
        };
      };

      xdg.desktopEntries.mpv = {
        type = "Application";
        name = "mpvipc";
        icon = "mpv";
        exec = "mpv --player-operation-mode=pseudo-gui --input-ipc-server=/tmp/mpv-socket";
        terminal = false;
        categories = [
          "AudioVideo"
          "Audio"
          "Video"
          "Player"
          "TV"
        ];
        mimeType = import ./_mpv-mime-a.nix ++ import ./_mpv-mime-b.nix;
      };
    };
}
