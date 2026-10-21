# The `files` flake-module (sini/files module.nix) evaluated over the fleet's fileModules for one pkgs.
# fileModules is the output of the files class (platforms/files.nix); modules take `pkgs` from specialArgs.
{ lib, inputs }:
pkgs:
(lib.evalModules {
  modules = [
    (inputs.files + "/module.nix")
    { files.root = inputs.self; }
  ]
  ++ inputs.self.fileModules;
  specialArgs = { inherit pkgs; };
}).config.files
