{ ... }:
{
  # Second file of hardware-vr-amd: user services for WayVR and Monado.
  ren.aspects.hardware-vr-amd.nixos =
    { pkgs, ... }:
    {
      # WayVR registers an OpenVR autostart manifest holding its own store
      # path, which goes stale after a GC. `--replace` rewrites it each login.
      # https://wiki.nixos.org/wiki/VR#SteamVR_autostart
      # Correct for our Monado/xrizer path. Under SteamVR as the compositor
      # WayVR must be launched as `steam-run wayvr` instead, because Steam's
      # FHS blocks it -- https://vronlinux.org/docs/distros/nixos/
      systemd.user.services.wayvr = {
        description = "WayVR desktop overlay for OpenXR/OpenVR";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.wayvr}/bin/wayvr --replace";
          Restart = "on-failure";
        };
      };

      systemd.user.services.monado = {
        serviceConfig.LimitNOFILE = 8192;
        environment = {
          AMD_VULKAN_ICD = "RADV";
          STEAMVR_LH_ENABLE = "1";
          XRT_COMPOSITOR_COMPUTE = "1";
          WMR_HANDTRACKING = "1";
          XRT_DEBUG_VK = "1";
          XRT_COMPOSITOR_FORCE_WAYLAND_DIRECT = "1";
          XRT_COMPOSITOR_SCALE_PERCENTAGE = "150";
          OXR_VIEWPORT_SCALE_PERCENTAGE = "125";
          U_PACING_COMP_PRESENT_TO_DISPLAY_OFFSET = "5";
          U_PACING_APP_USE_MIN_FRAME_PERIOD = "1";
          XRT_COMPOSITOR_FORCE_GPU_INDEX = "0";
          IPC_EXIT_WHEN_IDLE = "on";
          IPC_EXIT_WHEN_IDLE_DELAY_MS = "300000";
        };
      };
    };
}
