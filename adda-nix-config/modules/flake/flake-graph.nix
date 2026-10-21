# flake-graph: the `flake-graph-gen` package (flake.lock as an svg) and the aspect that puts both tools on a user's PATH.
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  # every user had these tools by default: included by whoever wants them
  ren.aspects.flake-graph.at = ren.kinds.user; # den.default.homeManager: every user
  ren.aspects.flake-graph.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        (addax.omni pkgs).unified.flake-graph.packages.default
        (addax.selfPackages pkgs).flake-graph-gen
      ];
    };

  ren.aspects.pkg-flake-graph-gen = {
    at = ren.system.x86_64-linux;
    packages =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        inherit (pkgs) lib;
        flake-graph = (addax.omni pkgs).unified.flake-graph.packages.default;
      in
      {
        flake-graph-gen = pkgs.writers.writeNuBin "flake-graph-gen" /* nu */ ''
          def main [
            flake_lock_path: path = "./flake.lock", # Path to the flake.lock or a directory containing the flake.lock.
            --output (-o): path = "", # Where to save the generated file to. If 'output' is a directory, stores the graph to '<output>/flake-fraph.svg'. (Default = TMPDIR/tmp.XXXXXXXXXX.svg).
            --show (-s), # Whether to show the generated graph.
          ] {
            let flake_lock_path = $flake_lock_path | path expand
            let flake_lock_path_type = $flake_lock_path | path type
            let flake_lock = match $flake_lock_path_type {
              "file" => { $flake_lock_path }
              "dir" => { $flake_lock_path | path join "flake.lock" }
              _ => { error make
                "'flake_lock_path' must be a path to a 'flake.lock' or a directory with '<flake_lock_path>/flake.lock'."
              }
            }

            let output = if ($output | is-empty) { mktemp --tmpdir --suffix ".svg" } else { $output }

            let $output = $output
            | path expand
            | match ( $output | path type) {
                "dir" => { $output | path join "flake-graph.svg" }
                _ => { $output }
              }

            # FIXME: When '--size' gets fixed with missing fields, use the size version.
            # ${lib.getExe flake-graph} --size $flake_lock
            ${lib.getExe flake-graph} $flake_lock
            | ${lib.getExe' pkgs.graphviz "dot"} -T svg
            | save --force $output
            print $output

            if $show {
              xdg-open $output
            }
          }
        '';
      };
  };
}
