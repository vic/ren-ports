# Guests: microvm NixOS machines run by a host; no standalone output.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt maybe;
  t = lib.types;
in
{
  ren.kinds.guest = {
    is = ren.kinds.host;
    microvm.passthrough = opt (t.listOf t.str) [ ];
    # per-guest package set for microvm.vms.<n>.pkgs (sini cortex-cuda: CUDA nixpkgs-unstable); null = microvm builds it from the channel
    microvm.guestPkgs = maybe t.raw;
  };
}
