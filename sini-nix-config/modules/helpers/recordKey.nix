# recordKey r -> resource key: name, type and short content hash, so reordering never changes a key
# (den domains/_lib.nix).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  ren.helpers.recordKey =
    r:
    "${lib.replaceStrings [ "." "*" ] [ "_" "wildcard" ] r.name}_${r.type}_${
      builtins.substring 0 8 (builtins.hashString "sha256" r.content)
    }";
}
