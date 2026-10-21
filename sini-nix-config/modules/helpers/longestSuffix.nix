# longestSuffix candidates name -> the longest candidate zone that equals name or is a dot-suffix of it, or null
# (den domains/_lib.nix longestSuffix).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  ren.helpers.longestSuffix =
    candidates: name:
    lib.findFirst (z: name == z || lib.hasSuffix ".${z}" name) null (
      lib.sort (a: b: lib.stringLength a > lib.stringLength b) candidates
    );
}
