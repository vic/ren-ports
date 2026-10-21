# formatter: treefmt per system as `formatter.<sys>` (`nix fmt`) and the `checks.<sys>.treefmt` check.
{ ren, inputs, ... }:
let
  treefmt = import ./_treefmt.nix { inherit inputs; };
in
{
  ren.aspects.formatter-treefmt = {
    at = ren.system.x86_64-linux;
    formatter = { system, ... }: { treefmt = (treefmt system).config.build.wrapper; };
    checks = { system, ... }: {
      ${system.name}.treefmt = (treefmt system).config.build.check inputs.self;
    };
  };
}
