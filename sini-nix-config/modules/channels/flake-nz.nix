# channels n-z (flake/docs family): readme (docs/readme.nix; Q9 explicit order).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # sortOn/concatMapStringsSep are nixpkgs-only (fleet lib is ren.genLib)
in
{
  # any -> fleet; each value { order:int; text } sorted in `into` (replaces dag.entryBetween).
  # `into` returns keys: `files` names the files class, so the module forwards as class content.
  ren.channels.readme = {
    fold = ren.lib.fold.list;
    to = _: ren.kinds.fleet;
    into =
      { ... }:
      r: {
        files =
          { pkgs, ... }:
          {
            files.files = [ { path_ = "README.md"; drv = pkgs.writeText "README.md" (lib.concatMapStringsSep "\n" (s: s.text) (lib.sortOn (s: s.order) r)); } ];
          };
      };
  };
}
