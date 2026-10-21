# harena-nixos: NixOS benchmarking work server (a Proxmox clone on verifit3, run by Adda's work identity `ichocholaty`).
{ ren, ... }:
{
  ren.host.harena-nixos = {
    system = ren.system.x86_64-linux;
    users = [ ren.user.ichocholaty ];
    description = "NixOS benchmarking work server";
    longDescription = ''
      "harena" is Latin for "sand" ("sandbox" has no Latin equivalent) and the original spelling of "arena", where the
      "tools" fight each other for a better score: this VM runs the benchmarks.
    '';
    workstation = false;
    signingKey = "638494D81A0D060E03907C2621237F8E8C1472A5";
    swap.zram = { };
    vmAutologin = ren.user.ichocholaty;
  };
  ren.aspects.harena-nixos = {
    at = ren.host.harena-nixos;
    includes = [ ren.aspects.workVM ];
  };
}
