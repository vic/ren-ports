# readme: .github/README.md = the old README text (swarsel-readme.md, kept verbatim) + the Ren part from live data.
# `nix run .#write-readme` writes it; `checks.<system>.readme` fails when the file is out of date.
{ ren, inputs, ... }:
let
  text = builtins.readFile ./swarsel-readme.md + "\n" + import ./_readme-ren.nix { inherit ren; };
in
{
  ren.aspects.readme = {
    at = ren.system.x86_64-linux;
    packages =
      { system, ... }:
      {
        write-readme = system.legacyPackages.writeShellApplication {
          name = "write-readme";
          meta.description = "Write .github/README.md";
          text = ''
            cp --no-preserve=mode ${system.legacyPackages.writeText "README.md" text} .github/README.md
          '';
        };
      };
    checks =
      { system, ... }:
      {
        readme = system.legacyPackages.runCommand "readme-up-to-date" { } ''
          cmp ${system.legacyPackages.writeText "README.md" text} ${inputs.self + "/.github/README.md"}
          touch $out
        '';
      };
  };
}
