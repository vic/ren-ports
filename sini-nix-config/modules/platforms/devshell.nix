# devshell class: per-system aspects emit numtide devshell modules into devShells.<system>.default.
{ ren, inputs, ... }:
{
  ren.classes.devshell = {
    at = ren.kinds.system;
    into =
      { system, ... }:
      ms: {
        devShells.${system.name}.default = inputs.devshell.legacyPackages.${system.name}.mkShell { imports = ms; };
      };
  };
  # numtide devshell modules get their own args (pkgs); per-system inputs come from the `system` binding in content:
  # `{ system, ... }: ... inputs.<x>.packages.${system.name}` (features/devshell/*), which replaces den inputs'.
}
