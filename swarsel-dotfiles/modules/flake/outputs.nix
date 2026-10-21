# flake outputs that are not machines: lib, templates, packages, apps (old flake/{lib,templates,packages,apps}.nix)
{ ren, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  sw = ren.helpers;
  linux = ren.lib.when (s: builtins.elem s.system.name sw.linuxSystems);
  appNames = [
    "swarsel-bootstrap"
    "swarsel-install"
    "swarsel-rebuild"
    "swarsel-postinstall"
  ];
  templateNames = [
    "python"
    "rust"
    "go"
    "cpp"
    "latex"
    "default"
  ];
  # nixpkgs lib with `hm` and `swarselsystems` (old outputs.lib, outputs.homeLib)
  extendedLib = lib.extend (
    _: _: {
      inherit (inputs.home-manager.lib) hm;
      swarselsystems = sw;
    }
  );
in
{
  ren.aspects.flake-outputs = {
    at = ren.fleet.swarsel;
    flake =
      { globals-defs, ... }:
      {
        # old perSystem outputs `pkgs` and `globals`
        pkgs = builtins.mapAttrs (_: s: s.legacyPackages) ren.system;
        globals = builtins.mapAttrs (_: _: sw.globalsOf globals-defs) ren.system;
        lib = extendedLib;
        homeLib = extendedLib;
        swarselsystemsLib = sw;
        templates = builtins.listToAttrs (
          map (name: {
            inherit name;
            value = {
              description = "${name} project ";
              path = sw.root "files/templates/${name}";
            };
          }) templateNames
        );
      };
  };

  # pkgs/flake: one package per directory, on linux systems
  ren.aspects.flake-packages = {
    at = ren.lib.and [
      ren.kinds.system
      linux
    ];
    packages = { system, ... }: import "${inputs.self}/pkgs/flake" {
      self = inputs.self;
      lib = extendedLib; # old self.outputs.lib
      pkgs = system.legacyPackages;
    };
  };

  ren.aspects.flake-apps = {
    at = ren.kinds.system;
    apps =
      { system, ... }:
      let
        appSet = builtins.listToAttrs (
          map (name: {
            inherit name;
            value = {
              program = "${inputs.self.packages.${system.name}.${name}}/bin/${name}";
              type = "app";
              meta.description = "Custom app ${name}.";
            };
          }) appNames
        );
      in
      appSet // { default = appSet.swarsel-bootstrap; };
  };
}
