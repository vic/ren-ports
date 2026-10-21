# k3s-containerd: containerd runtime with the zfs snapshotter and Cilium CNI.
#
# Stock nixpkgs containerd ships the zfs snapshotter compiled in (gated only by `!no_zfs`, which
# nixpkgs never sets). It just needs the `zfs` binary on the service PATH, since the snapshotter
# shells out to it. Layers become per-image CoW datasets under the dedicated child dataset mounted
# at /var/lib/containerd/io.containerd.snapshotter.v1.zfs, so they live outside the nix store and
# are never reaped by nix-collect-garbage. overlayfs is the fallback on non-zfs hosts.
# (nix-snapshotter was retired: no workload used nix-backed images and its store-path layers were
# GC-vulnerable.) Plugin settings: containerd-settings.nix.
{ ren, lib, ... }:
{
  ren.aspects.svc-k3s-containerd = {
    nixos =
      { host, is, pkgs, ... }:
      let
        c = import ./_containerd-lib.nix { inherit ren is pkgs host; };
      in
      {
        systemd.services.k3s.requires = [ "containerd.service" ];

        systemd.services.containerd = {
          serviceConfig.LimitNOFILE = lib.mkForce null;
          path = [
            # mkfs.erofs so the EROFS differ initializes instead of failing —
            # on containerd <2.3.1 a failed EROFS differ breaks the transfer
            # plugin's unpacker ("no unpack platforms defined"), so CRI can't
            # unpack the sandbox image. Fixed upstream in 2.3.1 (#13364); kept
            # here as belt-and-suspenders alongside the version override.
            pkgs.erofs-utils
          ]
          # The zfs snapshotter execs the `zfs` CLI; without it on PATH the
          # plugin fails to init and CRI reports the snapshotter "not found".
          ++ lib.optional c.useZfs pkgs.zfs
          # containerd resolves the runsc handler's shim
          # (containerd-shim-runsc-v1) on PATH, and the shim execs `runsc`.
          ++ lib.optional c.gvisor pkgs.gvisor;
        };

        environment.etc = {
          "cni/net.d".enable = false;
          "cni/net.d/05-cilium.conf" = {
            text = builtins.toJSON {
              cniVersion = "0.3.1";
              enable-debug = true;
              log-file = "/var/run/cilium/cilium-cni.log";
              name = "cilium";
              type = "cilium-cni";
            };
            mode = "0644";
          };
        };
      };

    # /var/lib/containerd is intentionally absent: on zfs hosts it is its own
    # dataset (provisioned by zfs-disk-single), so it persists itself and a
    # bind-mount here would shadow the dataset mountpoint.
    persist.directories = [
      "/var/lib/cni"
      "/var/lib/containers"
      "/var/lib/dockershim"
    ];
  };
}
