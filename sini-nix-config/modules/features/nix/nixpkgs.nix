{ inputs, ... }:
let
  config = {
    allowUnfree = true;
    allowDeprecatedx86_64Darwin = true;
  };
in
{
  ren.aspects.nix-nixpkgs = {
    # Shared base overlays, contributed through the nixpkgs-overlays channel.
    nixpkgs-overlays = builtins.attrValues (import ../../../pkgs/overlays.nix { inherit inputs; }) ++ [
      # pkgs.local = this flake's own packages; lazy, so it only forces outputs when a package reads it.
      (final: _prev: { local = inputs.self.packages.${final.stdenv.hostPlatform.system}; })
    ];

    # Overlays reach nixpkgs.overlays via the nixpkgs-overlays channel `into`
    # (channels/overlays-nz.nix); den's os block also set overlays = unique pool.
    os.nixpkgs = { inherit config; };

    # The per-user home-manager nixpkgs: only when the host does not share its nixpkgs,
    # otherwise home-manager.useGlobalPkgs trips an assertion on nixpkgs.* here.
    # useGlobalPkgs field is declared by the users-home-manager-shared lane.
    homeManager =
      { host, lib, ... }:
      lib.mkIf (!host.users-home-manager-shared.useGlobalPkgs) {
        nixpkgs = { inherit config; };
      };
  };
}
