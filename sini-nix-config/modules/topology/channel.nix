# Channels (data kind): nixpkgs + home-manager + nix-darwin triple, and the system builders.
{ ren, lib, inputs, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  ren.kinds.channel = {
    nixpkgs = t.raw;
    home-manager = t.raw;
    darwin = t.raw;
    nixosSystem = opt t.raw inputs.nixpkgs.lib.nixosSystem;
    darwinSystem = opt t.raw inputs.nix-darwin.lib.darwinSystem;
  };

  ren.channel.nixos-stable = {
    nixpkgs = inputs.nixpkgs;
    home-manager = inputs.home-manager;
    darwin = inputs.nix-darwin;
  };
  ren.channel.nixos-unstable = {
    nixpkgs = inputs.nixpkgs-unstable;
    home-manager = inputs.home-manager-unstable;
    darwin = inputs.nix-darwin-unstable;
  };
  ren.channel.nixpkgs-master = {
    nixpkgs = inputs.nixpkgs-master;
    home-manager = inputs.home-manager-master;
    darwin = inputs.nix-darwin-unstable;
  };
  ren.channel.nixpkgs-stable-darwin = {
    nixpkgs = inputs.nixpkgs-stable-darwin;
    home-manager = inputs.home-manager-stable-darwin;
    darwin = inputs.nix-darwin;
  };
  ren.channel.nix-darwin-unstable = {
    nixpkgs = inputs.nixpkgs-unstable;
    home-manager = inputs.home-manager-unstable;
    darwin = inputs.nix-darwin-unstable;
  };
}
