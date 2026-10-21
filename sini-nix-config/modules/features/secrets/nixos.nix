# Wraps the standalone agenix generators NixOS module.
{ ... }:
{
  ren.aspects.secrets-agenix-generators-nixos.nixos.imports = [ ./_generators-module.nix ];
}
