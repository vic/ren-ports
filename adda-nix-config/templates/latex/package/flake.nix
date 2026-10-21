{
  description = "A Nix-flake-based LaTeX development environment";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      self,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      #with flake-utils.lib; eachSystem allSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        tex = pkgs.texliveFull.withPackages (
          ps: with ps; [
            latexmk

            # latex-bin
            # scheme-full
          ]
        );
      in
      rec {
        devShells = {
          #devShells = forEachSupportedSystem ({ pkgs }: {
          default = pkgs.mkShell {
            packages = with pkgs; [
              texliveFull
              texlab
              tectonic
              rubber
            ];
          };
        };
        #});

        packages = {
          document = pkgs.stdenvNoCC.mkDerivation rec {
            name = "latex-demo-document";
            src = self;
            buildInputs = with pkgs; [
              coreutils
              tex
              texliveFull
              texlab
              tectonic
              rubber
              gnumake
            ];
            phases = [
              "unpackPhase"
              "buildPhase"
              "installPhase"
            ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";
              # mkdir -p .cache/texmf-var
              # env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
                # latexmk -interaction=nonstopmode -pdf -lualatex \
                # main.tex
              make
            '';
            installPhase = ''
              mkdir -p $out
              cp main.pdf $out/
            '';
          };
        };
        defaultPackage = packages.document;
      }
    );
}
