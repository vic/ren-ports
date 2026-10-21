# Firefox. Settings in _firefox-settings.nix, search engines in _firefox-search.nix.
{ inputs, ... }:
{
  ren.aspects.app-browsers-firefox = {
    homeManager =
      { pkgs, ... }:
      let
        addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        programs.firefox = {
          enable = true;

          profiles = {
            default = {
              id = 0;
              isDefault = true;

              extensions.packages = with addons; [
                bitwarden
                ublock-origin
                sponsorblock
                darkreader
                ghostery
                return-youtube-dislikes
                firefox-color
                duckduckgo-privacy-essentials
                mal-sync
                sidebery
              ];

              preConfig = builtins.readFile "${inputs.betterfox.outPath}/user.js";
              userChrome = builtins.readFile "${inputs.shimmer.outPath}/userChrome.css";
              userContent = builtins.readFile "${inputs.shimmer.outPath}/userContent.css";

              extraConfig = builtins.concatStringsSep "\n" [
                (builtins.readFile "${inputs.betterfox.outPath}/Securefox.js")
                (builtins.readFile "${inputs.betterfox.outPath}/Fastfox.js")
                (builtins.readFile "${inputs.betterfox.outPath}/Peskyfox.js")
              ];

              settings = import ./_firefox-settings.nix;

              search = import ./_firefox-search.nix pkgs;
            };
          };
        };
      };

    # Desktop-file MIME associations are Linux-only; on darwin firefox is set as
    # the default browser through System Settings.
    homeLinux = {
      xdg.mimeApps.defaultApplications = {
        "text/html" = [ "firefox.desktop" ];
        "text/xml" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
      };
    };

    stylix-hm = {
      targets.firefox.profileNames = [ "default" ];
      # TODO: bind this to linux only
      # targets.firefox.firefoxGnomeTheme.enable = true;
    };

    cacheHome.directories = [
      ".cache/mozilla"
    ];

    # home-manager ≥ the nixpkgs bump migrated firefox to the XDG path
    # (~/.config/mozilla/firefox). Firefox prefers legacy ~/.mozilla when it
    # exists, so persist the XDG path and let ~/.mozilla get wiped on boot.
    persistHome.directories = [
      ".config/mozilla/firefox"
    ];
  };
}
