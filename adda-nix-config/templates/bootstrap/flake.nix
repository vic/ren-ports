{
  description = "Flake to boostrap into the repository for a new machine";

  nixConfig = {
    accept-flake-config = true;
    allow-import-from-derivation = true;
    require-sigs = false;
    auto-optimise-store = true;
    extra-experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.flox.dev"
      "https://numtide.cachix.org"
      "https://cache.numtide.com"
      "https://devenv.cachix.org https://cachix.cachix.org"
      "https://helix.cachix.org"
    ];
    trusted-users = [
      "root"
      "adda"
      "@wheel"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE"
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    ];
    lazy-trees = true;
    submodules = true;
    use-xdg-base-directories = true;
  };

  inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat.url = "github:nix-community/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    make-shell = {
      url = "github:nicknovitski/make-shell";
      inputs.flake-compat.follows = "flake-compat";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-stable.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/x86_64-linux";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      hostName = "HOST-nixos"; # TODO: Specify host name.
    in
    {
      # Used with `nixos-rebuild --flake .#<hostname>`
      # nixosConfigurations."<hostname>".config.system.build.toplevel must be a derivation
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          inputs.disko.nixosModules.disko
        ];
      };

      # # Utilized by `nix develop`
      # devShell.x86_64-linux = rust-web-server.devShell.x86_64-linux;

      # # Utilized by `nix develop .#<name>`
      # devShells.x86_64-linux.example = self.devShell.x86_64-linux;
      # };
    };
}
