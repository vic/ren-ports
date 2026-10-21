{ inputs, ... }:
{
  ren.aspects.app-media-spicetify = {
    homeManagerModules = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

    homeManager =
      { pkgs, ... }:
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      in
      {
        programs.spicetify = {
          enable = true;
          enabledExtensions = with spicePkgs.extensions; [
            fullAppDisplay
            playlistIcons
            shuffle
            skipStats
            trashbin
          ];
          enabledCustomApps = with spicePkgs.apps; [
            lyricsPlus
            marketplace
            newReleases
          ];
          enabledSnippets = with spicePkgs.snippets; [
            betterLyricsStyle
            fixedEpisodesIcon
            fixLikedButton
            fixLikedIcon
            fixListeningOn
            fixListenTogetherButton
            fixNowPlayingIcon
            hideAudiobooksButton
            hideFriendActivityButton
            pointer
          ];
        };
      };

    firewall = {
      # Local Discovery and Google Cast ports
      networking.firewall.allowedTCPPorts = [ 57621 ];
      networking.firewall.allowedUDPPorts = [ 5353 ];
    };
  };
}
