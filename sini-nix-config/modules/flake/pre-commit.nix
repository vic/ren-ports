# pre-commit: git-hooks.nix with prek running treefmt.
# pre-commit class (like platforms/treefmt.nix for treefmt-nix): the git-hooks.nix modules (nix/run.nix) evaluated per
# system; the installation script is forwarded into the devshell startup, the treefmt hook runs the formatter output.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # nixpkgs evalModules/types for class content (fleet lib is ren.genLib)
  src = inputs.git-hooks-nix;
in
{
  ren.classes.pre-commit = {
    at = ren.kinds.system;
    into =
      { system, outputs, ... }:
      ms:
      let
        pkgs = system.legacyPackages;
        cfg =
          (lib.evalModules {
            modules = [
              (src + "/modules/all-modules.nix")
              {
                _module.args = { inherit pkgs; };
                tools = import (src + "/nix/call-tools.nix") pkgs;
                rootSrc = inputs.self.outPath;
                package = lib.mkDefault pkgs.pre-commit;
                hooks.treefmt.package = lib.mkOverride 900 outputs.formatter.${system.name};
              }
            ]
            ++ ms;
          }).config;
      in
      {
        devshell.devshell.startup.git-hooks.text = cfg.installationScript;
      };
  };

  ren.aspects.flake-pre-commit = {
    at = ren.kinds.system;
    flake-inputs = { ... }: { git-hooks-nix.url = "github:cachix/git-hooks.nix"; };
    # No flake check (check.enable = false upstream): the class emits no `checks`.
    pre-commit =
      { pkgs, system, ... }:
      {
        # prek instead of pre-commit avoids the dotnet dependency
        package = inputs.git-hooks-nix.packages.${system.name}.prek or pkgs.prek;
        hooks = {
          treefmt.enable = true; # package: the formatter output, set by the class
          nixidy-sync = {
            enable = true;
            name = "nixidy-sync";
            description = "Run nixidy-sync to re-generate argocd manifests";
            entry = "${inputs.self.packages.${system.name}.nixidy-sync}/bin/nixidy-sync --skip-secrets";
            files = "^(flake\\.lock|modules/features/k8s/.*\\.nix)$";
            pass_filenames = false;
          };
        };
      };
  };
}
