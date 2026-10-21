{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.amdcpu.nixos.config.hardware.cpu.amd.updateMicrocode = true;
}
