{ inputs, ... }:
{
  ren.aspects.hardware-vr-amd = {
    nixos =
      { pkgs, ... }:
      {
        imports = [
          inputs.nixpkgs-xr.nixosModules.nixpkgs-xr
        ];

        nixpkgs.xr.enable = true;

        hardware.graphics.extraPackages = [ pkgs.monado-vulkan-layers ];

        # https://wiki.nixos.org/wiki/VR#Applying_as_a_NixOS_kernel_patch
        #
        # The patch rewrites amdgpu_ctx_priority_permit()'s final `return
        # -EACCES` to `return 0`, so any process on the system can take a
        # high-priority GPU context. Async reprojection needs one.
        #
        # Disabled because our OpenXR path is Monado (active_runtime.json below)
        # reached via xrizer, and services.monado.highPriority already puts a
        # cap_sys_nice+eip wrapper on monado-service, which satisfies the
        # unpatched check. This is NOT a general substitute: Steam runs under
        # bubblewrap in a user namespace that strips capabilities outright, so
        # no security.wrappers entry can help SteamVR's own runtime or the
        # flatpak WiVRn. If SteamVR async reprojection regresses, the cheapest
        # remedy is a manual setcap on Steam's own binary, which lives outside
        # the store and can therefore hold file capabilities:
        #   sudo setcap CAP_SYS_NICE=eip \
        #     ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
        # https://vronlinux.org/docs/distros/nixos/
        #
        # boot.kernelPatches = [
        #   {
        #     name = "amdgpu-ignore-ctx-privileges";
        #     patch = pkgs.fetchpatch {
        #       name = "cap_sys_nice_begone.patch";
        #       url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
        #       hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
        #     };
        #   }
        # ];

        # Headset-specific udev rules live in their own aspect, e.g.
        # hardware.bigscreen-beyond.
        services.udev.packages = [ pkgs.openvr ];

        programs.steam.extraCompatPackages = [ pkgs.proton-ge-rtsp-bin ];

        environment.systemPackages = [
          pkgs.monado-vulkan-layers
          pkgs.libsurvive
          pkgs.xrgears
          pkgs.openvr
          pkgs.libusb1
          pkgs.bs-manager
          pkgs.wayvr
          pkgs.resolute
          pkgs.lighthouse-steamvr
          pkgs.monado
          pkgs.xrizer
          #pkgs.sidequest # TODO: insecure
        ];

        services.monado = {
          enable = true;
          defaultRuntime = false;
          highPriority = true;
          #package = pkgs.custom-monado;
        };
      };
  };
}
