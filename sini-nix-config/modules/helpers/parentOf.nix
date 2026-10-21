# parentOf candidates name -> nearest proper ancestor of `name` among candidates, or null
# (den domains/_lib.nix parentOf over longestSuffix).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  ren.helpers.parentOf = candidates: name: ren.helpers.longestSuffix (lib.remove name candidates) name;
}
