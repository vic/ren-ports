# containerd CRI runtime + transfer plugin settings (runc, optional gVisor). See containerd-settings.nix.
{ ren, lib, ... }:
{
  ren.aspects.svc-k3s-containerd.nixos =
    { host, is, pkgs, ... }:
    let
      c = import ./_containerd-lib.nix { inherit ren is pkgs host; };
    in
    {
  virtualisation.containerd.settings.plugins = {
        # Runtime service. cni intentionally omitted here — it arrives via
        # the grpc.v1.cri migration above. The old v2 config's
        # stream_server_address/port and disable_cgroup are intentionally
        # not carried over: disable_cgroup was removed in containerd 2.x,
        # and the streaming server defaults to 127.0.0.1 on an ephemeral
        # port (localhost-only, so the previously-pinned 10010 served no
        # purpose with the firewall disabled).
        "io.containerd.cri.v1.runtime" = {
          enable_selinux = false;
          enable_unprivileged_ports = true;
          enable_unprivileged_icmp = true;
          disable_apparmor = true;
          restrict_oom_score_adj = true;

          # The runc runtime's snapshotter must match the image service's,
          # or the sandbox controller looks for the pause snapshot in the
          # default snapshotter (overlayfs) while images were unpacked into
          # zfs -> "failed to get sandbox image ... not found". An empty
          # value does NOT inherit the image-service snapshotter.
          containerd.runtimes = {
            runc = {
              runtime_type = "io.containerd.runc.v2";
              inherit (c) snapshotter;
            };
          }
          # gVisor sandbox handler, selected by the `gvisor` RuntimeClass
          # (handler = "runsc"). Same snapshotter as runc, for the same
          # sandbox-image reason.
          // lib.optionalAttrs c.gvisor {
            runsc = {
              runtime_type = "io.containerd.runsc.v1";
              inherit (c) snapshotter;
            };
          };
        };

        # Belt-and-suspenders for any transfer-service path: unpack into
        # the same snapshotter CRI runs on.
        "io.containerd.transfer.v1.local".unpack_config = [
          {
            platform = "linux/amd64";
            inherit (c) snapshotter;
          }
        ];
      };
    };
}
