# treefmt class: evaluates treefmt-nix modules per system into `formatter.<system>` (nix fmt).
{ ren, inputs, ... }:
{
  ren.classes.treefmt = {
    at = ren.kinds.system;
    into =
      { system, ... }:
      ms: {
        formatter.${system.name} =
          (inputs.treefmt-nix.lib.evalModule system.legacyPackages { imports = ms; }).config.build.wrapper;
      };
  };
}
