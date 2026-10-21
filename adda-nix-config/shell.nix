# DO-NOT-EDIT.
# This file was auto-generated using github:sini/files.
# Use `nix run .#write-files` to regenerate it.

{
  system ? builtins.currentSystem,
}:
(builtins.getFlake (toString ./.)).devShells.${system}.default
