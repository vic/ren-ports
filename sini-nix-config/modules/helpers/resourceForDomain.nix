# resourceForDomain domain -> k8s-safe resource name: last two domain labels, hyphenated (den schema/cluster.nix).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  ren.helpers.resourceForDomain =
    domain:
    lib.concatStringsSep "-" (lib.reverseList (lib.take 2 (lib.reverseList (lib.splitString "." domain))));
}
