{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.formatter.flake-inputs = {
    pedantix = {
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "pre-commit-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
      url = "github:Swarsel/pedantix";
    };

    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };
  ren.aspects.formatter.at = ren.kinds.system;
  ren.aspects.formatter.flake-parts =
    { self, lib, ... }:
    lib.optionalAttrs (inputs ? treefmt-nix) {
  imports = [
    inputs.treefmt-nix.flakeModule
  ]
  ++ lib.optional (inputs ? pedantix) inputs.pedantix.flakeModules.default;

  perSystem = { pkgs, ... }: {
    # formatter is set by treefmt to:
    # formatter = lib.mkIf config.treefmt.flakeFormatter (lib.mkDefault config.treefmt.build.wrapper);
    treefmt = {
      programs = {
        deadnix.enable = true;
        shellcheck.enable = true;
        shfmt = {
          enable = true;
          # needed to replicate what my Emacs shfmt does
          # there is no builtin option for space-redirects
          package = pkgs.symlinkJoin {
            buildInputs = [ pkgs.makeWrapper ];
            name = "shfmt";
            paths = [ pkgs.shfmt ];
            postBuild = ''
              wrapProgram $out/bin/shfmt \
              --add-flags '-sr'
            '';
            meta.mainProgram = "shfmt";
          };
          indent_size = 4;
          simplify = true;
        };
        statix.enable = true;
      }
      // (
        if inputs ? pedantix then
          {
            pedantix = {
              enable = true;
              settings = import ../../files/nix/pedantix-settings.nix;
            };
          }
        else
          {
            nixfmt = {
              enable = true;
              package = pkgs.nixfmt;
            };
          }
      );
      projectRootFile = "flake.nix";
      settings.formatter.shellcheck.options = [
        "--shell"
        "bash"
      ];
    };
  };
    };
}
