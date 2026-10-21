# ipv4Of host -> primary IPv4 addresses: first interface with IPs, CIDR stripped (den host.nix ipv4).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  withIps = host: lib.findFirst (i: (i.ipv4 or [ ]) != [ ]) null (lib.attrValues host.networking.interfaces);
in
{
  ren.helpers.ipv4Of =
    host:
    if withIps host != null then
      map (a: builtins.head (lib.splitString "/" a)) (withIps host).ipv4
    else
      [ ];
}
