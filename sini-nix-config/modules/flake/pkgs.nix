# pkgs: local by-name packages (pkgs/by-name) exposed under pkgs.local, plus repo overlays.
# The per-system pkgs instance (nixpkgs-unstable, allowUnfree, repo overlays) is the `legacyPackages` field of
# the system instances (topology/system.nix).
{ ren, inputs, ... }:
{
  # pkgs-by-name-for-flake-parts (flake-module.nix): packagesFromDirectoryRecursive with `inputs` in the callPackage
  # scope, flattened to "<a>/<b>" names, into the packages class at every system.
  # shortcut: no nested-scope unwrapping (extractPackages upstream); by-name has no scope.nix dirs, add if one appears.
  ren.aspects.flake-pkgs = {
    at = ren.kinds.system;
    packages =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        inherit (pkgs) lib;
        scope = lib.makeScope pkgs.newScope (_: { inherit inputs; });
        tree = lib.filesystem.packagesFromDirectoryRecursive {
          directory = ../../pkgs/by-name;
          inherit (scope) newScope callPackage;
        };
        flatten =
          path: value:
          if lib.isDerivation value then
            { ${lib.concatStringsSep "/" path} = value; }
          else if lib.isAttrs value then
            lib.concatMapAttrs (n: flatten (path ++ [ n ])) value
          else
            { };
      in
      flatten [ ] tree;
  };

  # local packages under pkgs.local; consumed by nix-nixpkgs.
  ren.aspects.flake-pkgs-overlay.nixpkgs-overlays = { ... }: [
    (
      _final: prev: {
        local = inputs.self.packages.${prev.stdenv.hostPlatform.system};
      }
    )
  ];
}
