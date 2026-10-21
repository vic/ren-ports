{ inputs, ... }:
{
  ren.aspects.nix-lix = {
    nixos.imports = [ inputs.lix-module.nixosModules.default ];
    darwin.imports = [ inputs.lix-module.darwinModules.default ];
  };
}
