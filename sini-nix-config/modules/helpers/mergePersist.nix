# mergePersist entries -> { directories; files } union of persistence entries
# (den impermanence persist-collector / persist-home-collector).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  ren.helpers.mergePersist = entries: {
    directories = lib.unique (lib.concatMap (e: e.directories or [ ]) entries);
    files = lib.unique (lib.concatMap (e: e.files or [ ]) entries);
  };
}
