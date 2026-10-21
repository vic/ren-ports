# fulgur-nixos: Adda's work notebook (Lenovo ThinkPad T14 Gen 4 Ryzen).
{ ren, inputs, ... }:
{
  ren.host.fulgur-nixos = {
    system = ren.system.x86_64-linux;
    users = [ ren.user.adda ];
    description = "NixOS workstation for Work notebook Lenovo ThinkPad T14 Gen 4 Ryzen";
    longDescription = ''
      "fulgur" is Latin for "lightning": the fastest piece of hardware I own, and the one that does its work in short
      strikes — a notebook that is carried to wherever the work is, rebuilds the flake for the slower machines, and goes
       dark again.
    '';
    signingKey = "22146EBAB4684AE2907DDC228FC8E68432148DCA";
    swap = {
      # swapfile = { sizeGiB = 32; zswap = true; };
      zram = { };
      swapspace = true;
    };
    ttyAutologin = ren.user.adda;
    vmAutologin = ren.user.adda;
  };

  ren.aspects.fulgur-nixos = {
    at = ren.host.fulgur-nixos;
    nixos.imports = [
      ./_hardware.nix
      inputs.omniflake.unified.nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen4
    ];
    includes = with ren.aspects; [
      audio-pipewire
      fonts
      hardware-bareMetal
      kernel-xanmod
      filesystems-ntfs
      network-networkManager

      games

      network-tailscaleExitNodeClient

      ai-voxtype
    ];
  };
}
