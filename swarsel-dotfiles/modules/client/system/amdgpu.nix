{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.amdgpu.nixos.config.hardware.amdgpu = {
    initrd.enable = true;
    opencl.enable = true;
    # amdvlk = {
    #   enable = true;
    #   support32Bit.enable = true;
    # };
  };
}
