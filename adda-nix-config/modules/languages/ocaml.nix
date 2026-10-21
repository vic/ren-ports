# ocaml: opam, LSP and tooling.
{ ren, ... }:
{
  ren.aspects.languages-ocaml.zed-extensions = { ... }: [ "ocaml" ];

  ren.aspects.languages-ocaml.homeManager =
    { pkgs, ... }:
    {
      programs.opam.enable = true;

      home.packages = with pkgs; [
        ocamlPackages.lsp
        ocamlPackages.utop
        ocamlPackages.ocamlformat
        ocamlPackages.ocaml
        ocamlPackages.dune_3
        ocamlPackages.findlib
        ocamlPackages.odoc
      ];

      home.file.".ocamlinit".text = /* caml */ ''
        #require "core.top";;
        #require "ppx_jane";;
        open Base;;
      '';
    };
}
