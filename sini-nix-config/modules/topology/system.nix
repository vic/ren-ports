# Systems: per-system flake outputs live in their scopes.
# legacyPackages is stratum 0 data: it imports the repo overlays file directly and must not read the overlays channel pool (R:144-147).
{ lib, inputs, ... }:
let
  t = lib.types;
  pkgsFor =
    system:
    import inputs.nixpkgs-unstable {
      inherit system;
      config = {
        allowUnfree = true;
        allowDeprecatedx86_64Darwin = true;
      };
      overlays = lib.attrValues (import ../../pkgs/overlays.nix { inherit inputs; }) ++ [ inputs.nix-topology.overlays.default ];
    };
in
{
  ren.kinds.system.legacyPackages = t.raw;
  ren.system.x86_64-linux.legacyPackages = pkgsFor "x86_64-linux";
  ren.system.aarch64-linux.legacyPackages = pkgsFor "aarch64-linux";
  ren.system.aarch64-darwin.legacyPackages = pkgsFor "aarch64-darwin";
}
