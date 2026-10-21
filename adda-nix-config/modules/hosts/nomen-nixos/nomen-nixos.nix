# nomen-nixos: Adda's personal notebook (MSI).
{ ren, inputs, ... }:
{
  ren.host.nomen-nixos = {
    system = ren.system.x86_64-linux;
    users = [ ren.user.adda ];
    description = "NixOS workstation for Personal notebook MSI";
    longDescription = ''
      "nomen" is Latin for "name", and by extension a title: in this case the degree. This notebook went through the
      whole university with me and was the machine the Compurer Science degree was earned on, so it carries the name it
      helped me get.
    '';
    signingKey = "B56436B15771B81EEF5AD16DCB2C247091DDD43F";
    swap = {
      # swapfile = { sizeGiB = 16; zswap = true; };
      zram = { };
      swapspace = true;
    };
    ttyAutologin = ren.user.adda;
    vmAutologin = ren.user.adda;
  };

  ren.aspects.nomen-nixos = {
    at = ren.host.nomen-nixos;
    nixos.imports = [
      ./_hardware.nix
    ]
    ++ (with inputs.omniflake.unified.nixos-hardware.nixosModules; [
      common-cpu-amd
      common-gpu-amd
      common-pc-ssd
      common-pc-laptop
    ]);
    includes = with ren.aspects; [
      audio-pipewire
      fonts
      hardware-bareMetal
      kernel-xanmod
      filesystems-ntfs
      network-networkManager

      network-tailscaleExitNodeClient

      ai-voxtype
    ];
  };
}
