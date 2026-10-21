# nix-on-droid battery leftovers: flake input (class lives in droid.nix).
# drop-user-to-host-on-droid policy not ported: droid is its own kind with no user->host account route (Q7).
{ ren, ... }:
{
  ren.aspects.droid-input = {
    at = ren.kinds.fleet;
    flake-inputs.nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        home-manager.follows = "home-manager-unstable";
      };
    };
  };
}
