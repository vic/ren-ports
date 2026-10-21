# containerd settings (version 3 CRI plugin layout): root, grpc, CNI, image service. Runtime: containerd-runtime.nix; host wiring: containerd.nix.
{ ren, lib, ... }:
{
  ren.aspects.svc-k3s-containerd.nixos =
    { host, is, pkgs, ... }:
    let
      c = import ./_containerd-lib.nix { inherit ren is pkgs host; };
    in
    {
      virtualisation.containerd = {
        enable = true;

        settings = {
          # version 3 is REQUIRED for the split CRI plugin ids below
          # (io.containerd.cri.v1.images / .runtime). Under a version 2 config
          # containerd reads only the legacy io.containerd.grpc.v1.cri block
          # and silently ignores any v3 plugin keys — so the image-service
          # snapshotter/use_local_image_pull settings never took effect and
          # images kept unpacking into overlayfs (sandbox "image not found").
          version = lib.mkForce 3;

          root = "/var/lib/containerd";
          state = "/run/containerd";

          oom_score = 0;

          grpc = {
            address = "/run/containerd/containerd.sock";
          };

          plugins = {
            # CNI stays under the *legacy* grpc.v1.cri id (the only place the
            # nixpkgs module wires it). containerd's version-3 migration folds
            # this block into io.containerd.cri.v1.runtime, converting the
            # singular `bin_dir` into the v3 `bin_dirs` list. Defining cni here
            # rather than directly under cri.v1.runtime avoids the fatal
            # "bin_dir and bin_dirs cannot be set at the same time" — which is
            # what you get if both the migrated and the native key are present.
            "io.containerd.grpc.v1.cri".cni = {
              bin_dir = lib.mkForce "${c.k3s-cni-plugins}/bin/";
              conf_dir = "/etc/cni/net.d";
            };

            # Image service. snapshotter selects where layers unpack; this is
            # the authoritative snapshotter for CRI in 2.x. use_local_image_pull
            # bypasses the transfer service, whose CRI pull doesn't pass unpack
            # platforms ("no unpack platforms defined"); the local pull unpacks
            # straight into this snapshotter.
            # The sandbox image MUST be fully qualified. The podsandbox
            # controller resolves it via client.GetImage, a raw metadata
            # lookup with no docker.io normalization, while the image is
            # stored under its normalized key (docker.io/...). An unqualified
            # "rancher/mirrored-pause:3.6" therefore never matches -> "failed
            # to get sandbox image ... not found".
            "io.containerd.cri.v1.images" = {
              inherit (c) snapshotter;
              use_local_image_pull = true;
              pinned_images.sandbox = "docker.io/rancher/mirrored-pause:3.6";
            };
          };
        };
      };
    };
}
