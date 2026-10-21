# panix class: per-machine settings fragments -> channel panix-nodes (host -> fleet) -> panixModules + panix.yml build.
# Fleet build evaluates _panix-fleet/_panix-settings/_panix-hardened (verbatim den option tree) with lib.evalModules.
# Opt-in by use: classes with no fragments emit nothing (den.panix.enable/enableClass gates dropped).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # nixpkgs evalModules/types for class content (fleet lib is ren.genLib)
  inherit (ren.lib) and not;
  # deployer systems = the linux `system` instances (den config.systems); panix has no darwin package
  systems = lib.filter (lib.hasSuffix "-linux") (lib.attrNames ren.system);
  nodeOf =
    attr: m: ms:
    {
      ${m.name} = {
        inherit (m) name;
        system = m.system.name;
        deployment = ren.helpers.deployment m;
        intoAttr = [ attr m.name ];
        fragments = ms;
      };
    };
  evaluated =
    nodes:
    (lib.evalModules {
      modules = [ ./_panix-settings.nix ./_panix-hardened.nix ./_panix-fleet.nix ];
      specialArgs = { panixHosts = nodes; inherit systems; };
    }).config.den.panix;
  clean = v:
    if builtins.isAttrs v then lib.mapAttrs (_: clean) (lib.filterAttrs (_: x: x != null) v)
    else if builtins.isList v then map clean v
    else v;
  configFor =
    cfg: system: pkgs:
    let errs = cfg.violations (clean (builtins.fromJSON (builtins.toJSON cfg.fleets.${system})));
    in lib.throwIf (cfg.hardened && errs != [ ]) ''
      panix (hardened): the panix settings break these rules (set den.panix.hardened = false to opt out):
        - ${lib.concatStringsSep "\n  - " errs}'' (cfg.render pkgs cfg.fleets.${system});
  wrapper = import ./_panix-wrapper.nix;
in
{
  ren.channels.panix-nodes = {
    fold = ren.lib.fold.attrs;
    at = ren.kinds.machine;
    # fleet gets panixModules; each linux system scope gets its packages/checks as class content
    # (`packages`/`checks` name classes at `system`, so they cannot be returned from the fleet scope).
    to = _: ren.lib.anyOf [
      ren.kinds.fleet
      (and [ ren.kinds.system (ren.lib.when ({ system, ... }: lib.elem system.name systems)) ])
    ];
    into =
      { system ? null, ... }:
      nodes:
      let cfg = evaluated nodes;
      in
      if system == null then { panixModules = lib.mapAttrs (_: n: n.fragments) nodes; }
      else
        let pkgs = inputs.nixpkgs.legacyPackages.${system.name};
            panix-config = configFor cfg system.name pkgs;
        in {
          packages = { inherit panix-config; panix = wrapper { inherit pkgs lib panix-config; urlSentinel = cfg.urlSentinel; panix = inputs.panix.packages.${system.name}.default; }; };
          checks.drvs.panix-hardened = cfg.hardenedCheck pkgs;
        };
  };
  # packages/checks above forward into the system-scope packages/checks classes (platforms/outputs.nix).
  ren.classes.panix = [
    {
      at = and [ ren.kinds.host (not ren.kinds.guest) ];
      into = { host, ... }: ms: { panix-nodes = nodeOf "nixosConfigurations" host ms; };
    }
    {
      at = ren.kinds.mac;
      into = { mac, ... }: ms: { panix-nodes = nodeOf "darwinConfigurations" mac ms; };
    }
  ];
  # den: every nixos/darwin host with a flake output got defaults. An empty fragment makes the class land, so every metal host and mac is a fleet node.
  ren.aspects.panix-defaults = {
    at = ren.lib.anyOf [ ren.aspects.metal ren.kinds.mac ];
    panix = { };
  };
  ren.aspects.panix-input = {
    at = ren.kinds.fleet;
    flake-inputs.panix = {
      url = "github:mihakrumpestar/panix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "flake-utils";
      };
    };
  };
}
