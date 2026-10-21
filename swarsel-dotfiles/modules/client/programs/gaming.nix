{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects = {
    gaming.homeManager =
      {
        globals-defs,
        config,
        osConfig ? null,
        pkgs,
        ...
      }:
      let
        globals = sw.globalsOf globals-defs;
        confLib = sw.confLibOf { host = null; inherit globals config; inherit osConfig; };
        isNixos = osConfig != null;
      in
      {
        config = {
          programs.lutris = {
            enable = true;
            extraPackages = with pkgs; [
              winetricks
              gamescope
              umu-launcher
            ];
            protonPackages = with pkgs; [
              proton-ge-bin
            ];
            steamPackage = if isNixos then confLib.getConfig.programs.steam.package else pkgs.steam;
            winePackages = with pkgs; [
              wineWow64Packages.waylandFull
            ];
          };
          # specialisation = {
          #   gaming.configuration = {
          home.packages = with pkgs; [
            # lutris
            wine
            protonplus
            winetricks
            libudev-zero
            dwarfs
            fuse-overlayfs
            # steam
            steam-run
            patchelf
            gamescope
            vulkan-tools
            moonlight-qt
            ns-usbloader

            quark-goldleaf

            # gog games installing
            heroic

            # minecraft
            prismlauncher # has overrides
            temurin-bin-17

            pokefinder
            retroarch
            flips
          ];
          #   };
          # };
        };
      };
    gaming.nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      lib.mkMerge [
        {
          programs.steam = {
            enable = true;
            package = pkgs.steam;
            extraCompatPackages = [
              pkgs.proton-ge-bin
            ];
          };
        }
        (lib.mkIf (!config.swarselsystems.isMicroVM) {
        })
      ];
  };
}
