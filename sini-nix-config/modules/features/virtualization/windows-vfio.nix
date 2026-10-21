# Windows VFIO VM with GPU passthrough, hugepage management,
# and CPU isolation for near-native gaming performance. Qemu hook in windows-vfio-hook.nix.
{ ren, ... }:
{
  ren.aspects.virtualization-windows-vfio = {
    includes = with ren.aspects; [ hardware-gpu-nvidia-vfio ];

    gpu-claims = {
      device = "nvidia";
      priority = "interactive";
      kind = "libvirt";
    };

    nixos =
      { pkgs, ... }:
      {
        virtualisation.libvirtd = {
          enable = true;
          qemu = {
            swtpm.enable = true;
            vhostUserPackages = [ pkgs.virtiofsd ];
          };
        };
      };
  };
}
