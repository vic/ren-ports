# helpers: one NixOS module that also writes `globals` and `nodes.<name>` (oddlama's distributed config) becomes
# an aspect with three keys. `nixos` is the module without those writes; `globals-defs` and `nodes` are the same
# module evaluated as channel emissions. An emission never sees this machine's config (README "aspects"):
# a fragment that reads `config` fails loudly instead of reading another machine's value.
# Ren binds content args by the formals of a real lambda, so every function here names its formals.
{ ren, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  isA = t: v: builtins.isAttrs v && (v._type or null) == t;
  # the config part of a module result (explicit `{ config; options; imports; }` or the shorthand)
  isExplicit = r: r ? config || r ? options || r ? imports;
  configOf = r: if isExplicit r then r.config else r;
  # walk mkMerge / mkIf down to `key`
  pick =
    key: v:
    if isA "merge" v then
      lib.mkMerge (map (pick key) v.contents)
    else if isA "if" v then
      lib.mkIf v.condition (pick key v.content)
    else
      v.${key} or { };
  drop =
    keys: v:
    if isA "merge" v then
      v // { contents = map (drop keys) v.contents; }
    else if isA "if" v then
      v // { content = drop keys v.content; }
    else if builtins.isAttrs v && !(v ? _type) then
      removeAttrs v keys
    else
      v;
  # module args for an emission: the bindings, nixpkgs lib, and a throw for every other formal
  emitterArgs =
    module: bindings: overrides:
    builtins.mapAttrs (
      n: _: throw "ren: `${n}` is not available to the globals/nodes emission of ${bindings.host.name}"
    ) (builtins.functionArgs module)
    // { inherit lib; }
    // bindings
    // overrides;
  globalsOf = module: b: pick "globals" (configOf (module (emitterArgs module b { })));
  # the value is a module of the receiving node: only its `sops` is visible (kanidm secret paths), and
  # `nodes.<receiver>` is the receiver itself (old reads of the target node inside its forwarded block)
  nodesOf =
    module: b:
    { config, pkgs, ... }:
    pick "nodes" (
      configOf (
        module (
          emitterArgs module b {
            config = { inherit (config) sops; };
            nodes.${config.node.name} = { inherit config pkgs; };
          }
        )
      )
    );
  # NixOS side: the module without its globals/nodes writes; `nodes` stays empty (the name is the channel pool)
  stripped =
    module: args:
    let
      r = module (args // { nodes = { }; });
    in
    if isExplicit r then r // { config = drop [ "globals" "nodes" ] r.config; } else drop [ "globals" "nodes" ] r;
  distributedIf = cond: imports: module: {
    nixos =
      {
        host,
        globals-defs,
        variant,
        machine,
        config,
        lib,
        pkgs,
        options,
        utils,
        modulesPath,
        ...
      }@args:
      {
        imports = lib.optionals cond (imports ++ [ (stripped module args) ]);
      };
    globals-defs =
      {
        host,
        globals-defs,
        variant,
        machine,
        ...
      }@b:
      if cond then globalsOf module b else { };
    nodes =
      {
        host,
        globals-defs,
        variant,
        machine,
        ...
      }@b:
      if cond then nodesOf module b else _: { };
  };
in
{
  ren.helpers.pickDistributed = pick;
  ren.helpers.distributed = distributedIf true [ ];
  # for a module that only exists when `cond` holds (old `imports = lib.optionals (inputs ? x) [ ... ]`)
  ren.helpers.distributedIf = distributedIf;
}
