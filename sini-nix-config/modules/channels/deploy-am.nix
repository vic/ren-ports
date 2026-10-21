# a-m channels, deploy: colmena nodes, machine -> fleet (colmenaHive).
# Node = { imports; deployment = helpers.deployment record; system; channel (name); darwin }, emitted by the nixos and darwin classes.
# Mirrors sini batteries/colmena.nix hiveConfig: makeHive takes a function of localSystem; the receiver builds the colmena
# deployment/meta (nodeNixpkgs from the node's channel, buildOnTarget, darwin systemType). Channel pools carry names, not pkgs,
# so the `attrs` fold never merges big attrsets.
{ ren, lib, inputs, ... }:
{
  ren.channels.colmena-nodes = {
    fold = ren.lib.fold.attrs;
    at = ren.kinds.machine;
    to = _: ren.kinds.fleet;
    into =
      { ... }:
      nodes: {
        colmenaHive = inputs.colmena.lib.makeHive (
          { localSystem ? "x86_64-linux", ... }:
          lib.mapAttrs (
            _: n: {
              inherit (n) imports;
              deployment = {
                targetHost = n.deployment.address;
                targetUser = n.deployment.user;
                inherit (n.deployment) tags;
                allowLocalDeployment = true;
                buildOnTarget = n.system != localSystem;
              }
              // lib.optionalAttrs n.darwin { systemType = "darwin"; };
            }
          ) nodes
          // {
            meta = {
              nixpkgs = inputs.nixpkgs-unstable.legacyPackages.${localSystem};
              nix-darwin = inputs.nix-darwin-unstable;
              # colmena reads npkgs.path to find eval-config.nix: bare import, no double overlays
              nodeNixpkgs = lib.mapAttrs (
                _: n: import ren.channel.${n.channel}.nixpkgs { system = n.system; }
              ) nodes;
            };
          }
        );
      };
  };
}
