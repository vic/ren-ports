# scripts: nix-shell-with, nix-run-dot, nix-run-nixpkgs
{ ren, ... }:
{
  ren.aspects.shells-scripts.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.writers.writeNuBin "nix-shell-with" /* nu */ ''
          # Enter Nix shell with the passed packages avaliable.
          def main [...packages] {
            if ($packages | length) == 0 {
              error make "Missing arguments (>=1)"
            }
            nix shell ...($packages | each { |elt| $"nixpkgs#($elt)" })
          }

          # In Fish:
          # set -l packages $argv
          # if test (count $packages) -eq 0
          #     echo "Error: Missing arguments (>=1)"
          #     exit 1
          # end

          # set -l packages_str ""
          # if test (count $packages) -eq 1
          #     set packages_str $packages[1]
          # else
          #     set packages_str \{(string join ',' $packages)\}
          # end
          # eval nix shell nixpkgs#$packages_str
        '')
        (pkgs.writers.writeNuBin "nix-run-dot" /* nu */ ''
          # Run package from local directory.
          def main [package, ...args] {
            nix run --impure .#$package -- ...$args
          }
        '')
        (pkgs.writers.writeNuBin "nix-run-nixpkgs" /* nu */ ''
          # Run package from nixpkgs.
          def main [package, ...args] {
            nix run --impure nixpkgs#$package -- ...$args
          }
        '')
      ];
    };
}
