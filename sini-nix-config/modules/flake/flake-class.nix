# flake class: fleet-level top-level outputs (meta, imagesMetadata, chartsMetadata, ...), written as a module body.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # nixpkgs evalModules/types for class content (fleet lib is ren.genLib)
  # Ren reads an `into` result's key names to route forwards/emissions (ren/lib/classes.nix:80) before content
  # is evaluated; keys taken from the evaluated config cycle (infinite recursion), so they are listed here.
  # shortcut: a new flake-class output key must be added here, until Ren reads output keys lazily.
  outs = [
    "meta"
    "imagesMetadata"
    "images"
    "imageRefs"
    "chartsMetadata"
    "charts"
  ];
in
{
  ren.classes.flake = {
    at = ren.kinds.fleet;
    into =
      _: ms:
      let
        cfg =
          (lib.evalModules {
            modules = ms ++ [ { freeformType = lib.types.lazyAttrsOf lib.types.raw; } ];
          }).config;
      in
      lib.genAttrs outs (n: cfg.${n});
  };
}
