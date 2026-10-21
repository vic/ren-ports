# Steam user side, overlay and cache; same aspect as steam.nix.
{ ren, inputs, ... }:
{
  ren.aspects.app-gaming-steam = {
    # skip the hm steam when the host already has the aspect (den: !host.hasAspect gaming.steam)
    homeManager =
      {
        is,
        host,
        lib,
        pkgs,
        ...
      }:
      lib.mkIf (!(is ren.aspects.app-gaming-steam host)) {
        home.packages = [
          (pkgs.steam.override {
            extraEnv = {
              MANGOHUD = true;
              OBS_VKCAPTURE = true;
              PROTON_ENABLE_WAYLAND = true;
              PROTON_ENABLE_HDR = true;
              PROTON_USE_NTSYNC = true;
              PROTON_USE_WOW64 = true;
              RADV_TEX_ANISO = 16;
              PULSE_SINK = "Game";
            };
            extraPkgs =
              pkgs': with pkgs'; [
                qt6.qtwayland
                xdg-utils
                libx11
                libxext
                libxrender
                libxi
                libxinerama
                libxcursor
                libxscrnsaver
                libsm
                libice
                libxcb
                libxrandr
                libxkbcommon
                freetype
                fontconfig
                glib
                libpng
                libpulseaudio
                libvorbis
                libkrb5
                keyutils
                libglvnd
                libdrm
                vulkan-tools
                vulkan-loader
                vulkan-validation-layers
                vulkan-extension-layer
                (pkgs'.lib.getLib stdenv.cc.cc)
              ];
            extraLibraries = p: with p; [ atk ];
          })
        ];
      };

    nixpkgs-overlays = { ... }: [ inputs.proton-cachyos.overlays.default ];

    cacheHome.directories = [
      ".local/share/Steam"
    ];
  };
}
