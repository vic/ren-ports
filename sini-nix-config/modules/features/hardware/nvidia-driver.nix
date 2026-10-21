{ ... }:
{
  # Second file of hardware-gpu-nvidia: the hardware.nvidia driver package.
  ren.aspects.hardware-gpu-nvidia.nixos =
    { config, lib, ... }:
    {
      hardware.nvidia = {
        forceFullCompositionPipeline = false;
        modesetting.enable = true;
        powerManagement.enable = true;
        open = true;
        nvidiaSettings = false;
        nvidiaPersistenced = lib.mkDefault false;
        # nix-cachyos-kernel de-consts __to_hwgpio() with --replace-fail;
        # nvidia-open >=615 already ships it de-consted, so that substitution
        # aborts the build. Downgrade it to a warning.
        package = config.boot.kernelPackages.nvidiaPackages.latest.overrideAttrs (_: {
          passthru = config.boot.kernelPackages.nvidiaPackages.latest.passthru // {
            open = config.boot.kernelPackages.nvidiaPackages.latest.open.overrideAttrs (o: {
              postPatch = builtins.replaceStrings [ "--replace-fail" ] [ "--replace-warn" ] (o.postPatch or "");
            });
          };
        });
      };
    };
}
