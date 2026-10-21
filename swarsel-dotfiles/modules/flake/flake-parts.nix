# flake-parts: per-system flake-parts modules (devshell, treefmt, pre-commit, pedantix) evaluated once per system.
# `checks` and `formatter` are emissions into those channels; `devShells` is a top-level output.
{ ren, inputs, ... }:
{
  ren.classes.flake-parts = {
    at = ren.kinds.system;
    into =
      { system, ... }:
      ms:
      let
        fp = inputs.flake-parts.lib.mkFlake { inherit inputs; } {
          systems = [ system.name ];
          imports = ms;
        };
        out = name: fp.${name}.${system.name} or { };
      in
      {
        devShells.${system.name} = out "devShells";
        checks = out "checks";
        formatter = { treefmt = fp.formatter.${system.name}; };
        # nix-topology (modules/flake/topology.nix)
        topology.${system.name} = out "topology";
        # tests (modules/tests) build as packages
        packages = out "packages";
      };
  };
}
