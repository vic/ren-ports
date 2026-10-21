# meta: flake-level metadata (sini flake.meta), plain data on the fleet.
{ ren, ... }:
let
  owner = "sini";
  name = "nix-config";
in
{
  ren.aspects.flake-meta = {
    at = ren.kinds.fleet;
    flake.meta = {
      uri = "github:${owner}/${name}";
      repo = {
        forge = "github";
        inherit owner name;
        defaultBranch = "main";
        flakeUri = "git+https://github.com/${owner}/${name}?shallow=1";
      };
    };
  };
}
