# colmena: input only. Nodes are emitted by the nixos and darwin classes (platforms/nixos.nix, darwin.nix) into the
# colmena-nodes channel; channels/deploy-am.nix builds colmenaHive (meta, nodeNixpkgs, buildOnTarget, darwin systemType).
{ ren, ... }:
{
  # colmena fork with local-system detection (flake-inputs channel -> flake-file)
  ren.aspects.colmena-input.flake-inputs.colmena = {
    url = "github:sini/colmena/feat/local-system-detection";
    inputs = {
      nixpkgs.follows = "nixpkgs-unstable";
      flake-compat.follows = "flake-compat";
      flake-utils.follows = "flake-utils";
    };
  };
  ren.aspects.colmena-input.at = ren.kinds.fleet;
}
