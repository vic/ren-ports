# distributed config (after oddlama): `globals-defs` collects what every machine adds to the globals;
# `nodes` carries NixOS modules that one machine writes into another (old `nodes.<name>` option).
{ ren, inputs, ... }:
let
  inherit (ren.lib) anyOf;
  everyKind = anyOf [
    ren.kinds.fleet
    ren.kinds.system
    ren.kinds.machine
    ren.kinds.home
    ren.kinds.droid
    ren.kinds.user
  ];
  # receivers: every scope of the emitter's fleet (the sandbox fleet has its own globals)
  everyScope =
    e:
    ren.lib.and [
      everyKind
      (anyOf [
        e.fleet
        (ren.lib.within e.fleet)
      ])
    ];
in
{
  # each emission is one fragment of `globals`; a fold `list` keeps the typed merge of the globals module
  ren.channels.globals-defs = {
    fold = ren.lib.fold.list;
    # globals come from the full builds of machines only (old self.outputs.nodes), never from their users
    at = anyOf [
      ren.kinds.fleet # the static globals module of the fleet
      (ren.lib.and [
        (ren.lib.within ren.variant.full)
        ren.kinds.host
      ])
    ];
    to = everyScope;
  };
  ren.aspects.fleet-globals = {
    at = ren.kinds.fleet;
    globals-defs =
      { fleet, ... }:
      {
        __module = ren.helpers.importEncrypted fleet.globalsFile;
        __demo = fleet.isDemo;
      };
  };

  # old common/globals.nix + flake/globals.nix: the repository globals file plus every machine's fragments
  ren.helpers.globalsOf =
    defs:
    (inputs.nixpkgs.lib.evalModules {
      modules =
        let
          statics = builtins.filter (d: d ? __module) defs;
          demo = builtins.any (d: d.__demo) statics;
          fragments = builtins.filter (d: !(d ? __module)) defs;
        in
        [ ren.helpers.globalsModule ]
        ++ map (d: d.__module) statics
        ++ inputs.nixpkgs.lib.optionals (!demo) (map (d: { globals = d; }) fragments);
      prefix = [ "globals" ];
      specialArgs = {
        inherit inputs;
        inherit (inputs.nixpkgs) lib;
        inherit (inputs.topologyPrivate) topologyPrivate;
      };
    }).config.globals;

  # each emission is a module of the receiver `{ config, ... }: { <node name> = <config>; }` (helpers/distributed.nix)
  ren.channels.nodes = {
    fold = ren.lib.fold.list;
    # full builds of machines only (old self.outputs.nodes), never their users; every variant receives
    at = ren.lib.and [
      (ren.lib.within ren.variant.full)
      ren.kinds.host
    ];
    to =
      e:
      ren.lib.and [
        ren.kinds.machine
        (ren.lib.within e.fleet)
      ];
  };
  ren.aspects.nodes = {
    at = ren.kinds.machine;
    nixos =
      { host, nodes, ... }:
      {
        imports = map (e: { config, pkgs, ... }@a: { config = ren.helpers.pickDistributed host.name (e a); }) nodes;
      };
  };
}
