# getAssignment cluster name -> IP assigned to `name` in the first cluster network that has it (den schema/cluster.nix).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  foundIn = cluster: name: lib.findFirst (n: cluster.networks.${n}.assignments ? ${name}) null (lib.attrNames cluster.networks);
in
{
  ren.helpers.getAssignment =
    cluster: name:
    if foundIn cluster name != null then
      cluster.networks.${foundIn cluster name}.assignments.${name}
    else
      throw "ren: cluster assignment '${name}' not found";
}
