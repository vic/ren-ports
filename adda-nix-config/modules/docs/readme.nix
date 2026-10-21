# readme: README.md generated from live Ren data, written by `nix run .#write-files`.
{
  ren,
  inputs,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  # README parts: plain `_` files (import-tree skips them)
  vocabDirs = import ./_vocabulary-dirs.nix;
  ir = import ./_fleet-ir.nix {
    inherit ren;
    chans = import ./_fleet-channels.nix;
  };
  map' = import ./_readme-map.nix { inherit ir; };
  # old README text first (without its DO-NOT-EDIT header; files' warning format adds one)
  old = builtins.readFile ./adda-readme.md;
  intro = ''
    ## adda

    Adda's NixOS configurations in [Ren](https://github.com/vic/ren) (built on [Gen](https://github.com/sini/gen)).
    Generated file: edit `modules/docs/`, then run `nix run .#write-files`.
  '';
  # ren.lib is Gen's lib, so the nixpkgs lib comes from inputs
  hosts = import ./_readme-hosts.nix { inherit ren lib; };
in
{
  ren.aspects.readme = {
    at = ren.system.x86_64-linux;
    files =
      { config, ... }:
      {
        config.files.file."README.md" = {
          format = config.files.warning.format;
          text = builtins.concatStringsSep "\n" [
            old
            intro
            (import ./_readme-tour.nix)
            (import ./_readme-commands.nix)
            map'.scopes
            map'.more
            hosts
            (import ./_readme-adda.nix { inherit ren lib; })
            "## Directory structure\n\n${import ./_readme-dirs.nix { inherit vocabDirs; }}"
          ];
        };
      };
  };
}
