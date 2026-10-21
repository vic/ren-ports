# Steam system side. Package override lives in steam-package.nix, user side in steam-home.nix (same aspect).
{ ... }:
{
  ren.aspects.app-gaming-steam = {
    nixos =
      { pkgs, ... }:
      {
        nix.settings = {
          substituters = [ "https://nix-gaming.cachix.org" ];
          trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
        };

        environment.systemPackages = [
          pkgs.wine
          pkgs.winetricks
          pkgs.wineWow64Packages.waylandFull
        ];

        hardware = {
          steam-hardware.enable = true;
          graphics.enable32Bit = true;
        };

        programs = {
          appimage.enable = true;
          appimage.binfmt = true;

          steam = {
            enable = true;
            remotePlay.openFirewall = true;
            dedicatedServer.openFirewall = true;
            localNetworkGameTransfers.openFirewall = true;
            protontricks.enable = true;

            extraCompatPackages = [
              pkgs.proton-ge-bin
              pkgs.proton-cachyos-x86_64_v3
            ];

            gamescopeSession = {
              enable = true;

              env = {
                DXVK_HDR = "1";
              };

              args = [
                "--rt"
                "--hdr-enabled"
                "--hdr-itm-enabled"
                "--hdr-debug-force-output"
                "--xwayland-count 2"
                "-W 3840"
                "-H 2160"
                "-r 120"
              ];
            };
          };
        };
      };
  };
}
