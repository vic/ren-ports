# per-system flake outputs: each class at `system` writes <output>.<system>.
# The modules are evaluated with the system's pkgs (flatten would hand un-evaluated content `{}` for pkgs args).
# `formatter` is the treefmt class (platforms/treefmt.nix); `checks` is its own class below.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # nixpkgs evalModules/types for class content (fleet lib is ren.genLib)
  mk = name: {
    at = ren.kinds.system;
    into =
      { system, ... }:
      ms: {
        ${name}.${system.name} =
          (lib.evalModules {
            modules = ms ++ [ { freeformType = lib.types.lazyAttrsOf lib.types.raw; } ];
            specialArgs.pkgs = system.legacyPackages;
          }).config;
      };
  };
in
{
  ren.classes.packages = mk "packages";
  ren.classes.apps = mk "apps";
  ren.classes.legacyPackages = mk "legacyPackages";
  ren.classes.chartsDerivations = mk "chartsDerivations";
  ren.classes.imagesDerivations = mk "imagesDerivations";

  # Checks: each content key is one nixosTest at `checks.<sys>.<name>`; `drvs.<name>` is a ready check derivation.
  ren.classes.checks = {
    at = ren.kinds.system;
    into =
      { system, ... }:
      ms:
      let
        tests =
          (lib.evalModules {
            modules = ms ++ [
              {
                freeformType = lib.types.attrsOf lib.types.deferredModule;
                options.drvs = lib.mkOption {
                  type = lib.types.lazyAttrsOf lib.types.raw;
                  default = { };
                };
              }
            ];
            specialArgs.pkgs = system.legacyPackages;
          }).config;
      in
      {
        checks.${system.name} =
          builtins.mapAttrs (
            name: t:
            system.legacyPackages.testers.runNixOSTest {
              imports = [ t ];
              inherit name;
            }
          ) (removeAttrs tests [ "drvs" ])
          // tests.drvs;
      };
  };
}
