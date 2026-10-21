# scripts: man-tv, search man pages with television
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.shells-scripts.homeManager =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    {
      home.packages = [
        (pkgs.writers.writeNuBin "man-tv" /* nu */ ''
          # Search man pages with television.
          def main [...args] {
            match ($args | length) {
              0 => {
                ${getExeName pkgs.television} man-pages
              },
              1 => {
                ${getExeName pkgs.television} man-pages --input ($args.0)
              },
              _ => {
                error make "'man' accepts 0 or 1 arguments."
              }
            }
          }
        '')
      ];
    };
}
