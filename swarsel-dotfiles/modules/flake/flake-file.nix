# flake-file: the `flake-inputs` channel and the `flake-file` class write flake.nix (`nix run .#write-flake`).
{ ren, inputs, ... }:
{
  ren.channels.flake-inputs = {
    fold = ren.lib.fold.attrs;
    to = _: ren.system.x86_64-linux; # no `at`: any scope emits; received where the flake-file class is
    into = { ... }: i: { flake-file.flake-file.inputs = i; }; # a class key: forwarded as content
  };

  ren.classes.flake-file = {
    at = ren.system.x86_64-linux;
    into =
      { system, ... }:
      ms:
      let
        e = inputs.nixpkgs.lib.evalModules {
          specialArgs = { inherit inputs; }; # write-flake.nix reads `top.inputs.self`: only specialArgs reach `@top`
          modules = [ inputs.flake-file.flakeModules.flake ] ++ ms;
        };
        app = n: e.config.flake-file.apps.${n} system.legacyPackages;
      in
      {
        packages = {
          write-flake = app "write-flake";
          write-lock = app "write-lock";
        };
        checks.flake-file = e.config.flake-file.check-flake-file system.legacyPackages;
      };
  };

  ren.aspects.flake-file = {
    at = ren.system.x86_64-linux;
    flake-file.flake-file = {
      description = "SwarseFlake - Nix Flake for all SwarselSystems";
      outputs = "inputs: inputs.ren.lib.mkFlake inputs (inputs.import-tree ./modules)";
    };
    flake-inputs =
      { ... }:
      {
        # old common/dns.nix: globals and confLib read `inputs.dns`
        dns = {
          inputs = {
            flake-utils.follows = "flake-utils";
            nixpkgs.follows = "nixpkgs";
          };
          url = "github:kirelagin/dns.nix";
        };
        flake-file.url = "github:vic/flake-file";
        flake-parts = {
          inputs.nixpkgs-lib.follows = "nixpkgs";
          url = "github:hercules-ci/flake-parts";
        };
        flake-utils = {
          inputs.systems.follows = "systems";
          url = "github:numtide/flake-utils";
        };
        home-manager = {
          # url = "github:Swarsel/home-manager/main";
          inputs.nixpkgs.follows = "nixpkgs";
          url = "github:nix-community/home-manager";
        };
        import-tree.url = "github:vic/import-tree";
        nixos-extra-modules = {
          inputs = {
            devshell.follows = "devshell";
            flake-parts.follows = "flake-parts";
            nixpkgs.follows = "nixpkgs";
            pre-commit-hooks.follows = "pre-commit-hooks";
          };
          url = "github:oddlama/nixos-extra-modules/main";
        };
        nixos-hardware = {
          inputs.nixpkgs.follows = "nixpkgs";
          url = "github:NixOS/nixos-hardware/master";
        };
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        nixpkgs-dev.url = "github:Swarsel/nixpkgs/main";
        nixpkgs-kernelpin.url = "github:nixos/nixpkgs/567a49d1913ce81ac6e9582e3553dd90a955875f?narHash=sha256-lrp67w8AulE9Ks53n27I45ADSzbOCn4H%2BCNW1Ck8B%2B8%3D";
        nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
        nixpkgs-stable24_11.url = "github:NixOS/nixpkgs/nixos-24.11";
        nixpkgs-stable25_05.url = "github:NixOS/nixpkgs/nixos-25.05";
        nixpkgs-stable26_05.url = "github:NixOS/nixpkgs/nixos-26.05";
        ren.url = "github:vic/ren";
        swarsel-nix = {
          inputs = {
            flake-parts.follows = "flake-parts";
            nixpkgs.follows = "nixpkgs";
            systems.follows = "systems";
          };
          url = "github:Swarsel/swarsel-nix/main";
        };
        systems.url = "github:nix-systems/default";
      };
  };
}
