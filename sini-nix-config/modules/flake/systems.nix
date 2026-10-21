# systems: nix-systems list; flake-parts `systems` is the Ren system kind (topology lane), only the input stays.
{ ren, ... }:
{
  ren.aspects.flake-systems = {
    at = ren.kinds.fleet;
    flake-inputs = { ... }: { systems.url = "github:nix-systems/default/future-26.11"; };
  };
}
