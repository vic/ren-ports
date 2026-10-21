# Steam FHS package override (system side); same aspect as steam.nix.
{ ren, ... }:
{
  ren.aspects.app-gaming-steam.nixos =
    {
      is,
      host,
      lib,
      pkgs,
      ...
    }:
    {
      programs.steam.package = pkgs.steam.override {
        # Raw shell appended to the FHS profile. extraEnv is not usable
        # here: it goes through lib.toShellVars, which single-quotes.
        # https://vronlinux.org/docs/distros/nixos/
        extraProfile = ''
          # Without this, an XR title launched from Steam cannot see the
          # host OpenXR runtime and fails to reach Monado/WiVRn.
          export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
          # VRChat and friends otherwise misreport the timezone.
          unset TZ
        '';

        extraEnv = {
          MANGOHUD = true;
          OBS_VKCAPTURE = true;
          PROTON_ENABLE_WAYLAND = true;
          PROTON_ENABLE_HDR = true;
          PROTON_USE_NTSYNC = true;
          PROTON_USE_WOW64 = true;
          RADV_TEX_ANISO = 16;
          PULSE_SINK = "Game";
        }
        // lib.optionalAttrs (is ren.aspects.hardware-gpu-nvidia-prime host && is ren.aspects.hardware-laptop host) {
          NV_PRIME_RENDER_OFFLOAD = "1";
          "__NV_PRIME_RENDER_OFFLOAD_PROVIDER" = "NVIDIA-G0";
          "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
          "__VK_LAYER_NV_optimus" = "NVIDIA_only";
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
            (lib.getLib stdenv.cc.cc)
          ];

        extraLibraries = p: with p; [ atk ];
      };
    };
}
