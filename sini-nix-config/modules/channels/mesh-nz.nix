# channels n-z (mesh family): host -> host same env (C03 B,E; pipes.nix collect).
{ ren, ... }:
let
  sameEnv = e: ren.lib.and [ ren.kinds.host (ren.lib.when ({ host, ... }: ren.lib.same host.environment e.host.environment)) ];
  peers = {
    fold = ren.lib.fold.list;
    at = ren.kinds.host;
    to = sameEnv;
  };
in
{
  ren.channels.vault-peers = peers // { into = { ... }: p: { vault-peers = p; }; };
  ren.channels.thunderbolt-mesh-peers = peers // { into = { ... }: p: { thunderbolt-mesh-peers = p; }; };
  ren.channels.ollama-endpoints = peers // { into = { ... }: p: { ollama-endpoints = p; }; };
  ren.channels.ninfer-endpoints = peers // { into = { ... }: p: { ninfer-endpoints = p; }; };
  # sini den quirks/hipfire-endpoints.nix + pipes.nix:83 (same shape as ollama/ninfer); no reader yet.
  ren.channels.hipfire-endpoints = peers // { into = { ... }: p: { hipfire-endpoints = p; }; };
  # sini emits llama-cpp-endpoints with no quirk declared (den dropped it); declared so the emission lands, no reader yet.
  ren.channels.llama-cpp-endpoints = peers // { into = { ... }: p: { llama-cpp-endpoints = p; }; };
  # wiring unverified (C03:82); lane checks.
  ren.channels.nix-builders = peers // { into = { ... }: p: { nix-builders = p; }; };
}
