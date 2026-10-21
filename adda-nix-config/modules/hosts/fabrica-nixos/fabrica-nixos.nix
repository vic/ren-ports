# fabrica-nixos: NixOS development work server (a Proxmox clone on verifit3, run by Adda's work identity `ichocholaty`).
{ ren, ... }:
{
  ren.host.fabrica-nixos = {
    system = ren.system.x86_64-linux;
    users = [ ren.user.ichocholaty ];
    description = "NixOS development work server";
    longDescription = ''
      "fabrica" is Latin for "workshop" or a "forge": the VM where the actual
      development work is done.
    '';
    workstation = false;
    signingKey = "638494D81A0D060E03907C2621237F8E8C1472A5";
    swap.zram = { };
    vmAutologin = ren.user.ichocholaty;
  };
  ren.aspects.fabrica-nixos = {
    at = ren.host.fabrica-nixos;
    includes = [ ren.aspects.workVM ];
  };
}
