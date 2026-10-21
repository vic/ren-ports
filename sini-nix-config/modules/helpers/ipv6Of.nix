# ipv6Of host -> primary IPv6 addresses: first interface with IPs (den host.nix ipv6).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  withIps = host: lib.findFirst (i: (i.ipv6 or [ ]) != [ ]) null (lib.attrValues host.networking.interfaces);
in
{
  ren.helpers.ipv6Of = host: if withIps host != null then (withIps host).ipv6 else [ ];
}
