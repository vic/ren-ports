# channels: flake outputs that aspects emit. Per-system outputs come from system scopes; `flake` takes any top-level output.
{ ren, inputs, ... }:
let
  atSystem = {
    fold = ren.lib.fold.attrs;
    at = ren.kinds.system;
    to = e: e;
  };
  toFleet = {
    fold = ren.lib.fold.attrs;
    to = _: ren.kinds.fleet;
  };
in
{
  # also the sandbox host (its VM test), received by its system
  ren.channels.packages = atSystem // {
    at = ren.lib.anyOf [
      ren.kinds.system
      ren.helpers.sandboxed
    ];
    to = e: if e ? host then ren.system.${e.host.system.name} else e;
    into = { system, ... }: p: { packages.${system.name} = p; };
  };
  ren.channels.apps = atSystem // {
    into = { system, ... }: a: { apps.${system.name} = a; };
  };
  ren.channels.devshells = atSystem // {
    into = { system, ... }: s: { devShells.${system.name} = s; };
  };
  ren.channels.formatter = atSystem // {
    into = { system, ... }: f: { formatter.${system.name} = f.treefmt; };
  };
  ren.channels.checks = atSystem // {
    into = { system, ... }: c: { checks.${system.name} = c; };
  };
  # old flake-parts `flake.<output>`: overlays, templates, lib, homeModules, nixosModules, diskoConfigurations, pii
  ren.channels.flake = toFleet // {
    # keys must not depend on the pool (Ren stratum 3): one key per output
    into =
      { ... }:
      o:
      inputs.nixpkgs.lib.genAttrs [
        "lib"
        "homeLib"
        "swarselsystemsLib"
        "templates"
        "pkgs"
        "globals"
        "overlays"
        "stablePinsUnstable"
        "pii"
      ] (k: o.${k});
  };
}
