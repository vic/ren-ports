{ inputs, ... }:
{
  ren.aspects.system-disko.nixos.imports = [ inputs.disko.nixosModules.disko ];
}
