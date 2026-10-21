# Shared containerd inputs: CNI plugin env, snapshotter choice, gvisor flag.
{ ren, is, pkgs, host }:
let
  useZfs = is ren.aspects.disk-zfs-disk-single host;
in
{
  inherit useZfs;
  snapshotter = if useZfs then "zfs" else "overlayfs";
  gvisor = host.svc-k3s.gvisor;
  k3s-cni-plugins = pkgs.buildEnv {
    name = "k3s-cni-plugins";
    paths = [
      pkgs.cni-plugins
      # pkgs.cni-plugin-flannel # TODO: Flannel CNI plugin is currently broken in nixpkgs
      pkgs.local.cni-plugin-cilium
    ];
  };
}
