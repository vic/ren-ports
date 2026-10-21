# files: write-files app + devshell command + per-file checks; inputs `files` and `dag`.
# The files module (sini/files) is evaluated per system over the fleet's fileModules (_files-eval.nix).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # nixpkgs evalModules/types for class content (fleet lib is ren.genLib)
  filesOf = import ./_files-eval.nix { inherit lib inputs; };
in
{
  ren.aspects.flake-files = {
    at = ren.kinds.fleet;
    flake-inputs = { ... }: { dag.url = "github:denful/dag"; };
  };

  ren.aspects.flake-files-writer = {
    at = ren.kinds.system;
    devshell =
      { system, ... }:
      let
        writer = (filesOf system.legacyPackages).writer.drv;
      in
      {
        packages = [ writer ];
        commands = [
          {
            package = writer;
            help = "Generate files";
          }
        ];
      };
    apps =
      { system, ... }:
      {
        write-files = {
          type = "app";
          program = "${(filesOf system.legacyPackages).writer.drv}/bin/write-files";
        };
      };
    checks = { system, ... }: { drvs = (filesOf system.legacyPackages).checks; };
  };
}
