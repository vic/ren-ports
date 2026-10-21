# treefmt: formatter for `nix fmt` (treefmt-nix), settings here, programs in treefmt-programs.nix.
{ ren, lib, inputs, ... }:
let
  filesOf = import ./_files-eval.nix { inherit lib inputs; };
in
{
  ren.aspects.flake-treefmt = {
    at = ren.kinds.system;
    flake-inputs = { ... }: { treefmt-nix.url = "github:numtide/treefmt-nix"; };
    # `treefmt` is a class (platforms/treefmt.nix): its modules become formatter.<system> (nix fmt).
    treefmt =
      { pkgs, ... }:
      {
        # A regular file at the root of a checkout, a git worktree (where `.git` is a file and
        # `.git/config` is absent) and the flake check's copy (where `.git` is a directory, which
        # treefmt's tree-root-file search does not accept).
        projectRootFile = "flake.nix";

        enableDefaultExcludes = true;

        settings = {
          on-unmatched = "warn";

          global.excludes = [
            "generated/**"
            ".secrets/**"
            "*.editorconfig"
            "*.envrc"
            "*.gitconfig"
            "*.gitignore"
            "*CODEOWNERS"
            "*LICENSE"
            "*flake.lock"
            "*.svg"
            "*.png"
            "*.gif"
            "*.ico"
            "*.jpg"
            "*.webp"
            "*.conf"
            "*.age"
            "*.pub"
            "*.asc"
            "*.org"
            "*.zsh"
            "*.kdl"
            "*.txt"
            "*.tmpl"
            "*.jwe"
            "*.xml"
            "*.dds"
            "*.diff"
            "*.patch"
            "*.bin"
            # Underscore-prefixed files/dirs are ignored by the module auto-import system
            "**/_*/**"
            "**/_*"
          ]
          # generated files (the files flake-module paths) are not formatted
          ++ (filesOf pkgs).paths;

          mdformat.options = [ "--number" ];
          shellcheck.options = [
            "--shell=bash"
            "--check-sourced"
          ];
          yamlfmt.options = [
            "-formatter"
            "retain_line_breaks=true"
          ];
          formatter = {
            ruff-check.priority = 1;
            ruff-format.priority = 2;
            prettier.options = [
              "--tab-width"
              "2"
            ];
          };
        };
      };
  };
}
