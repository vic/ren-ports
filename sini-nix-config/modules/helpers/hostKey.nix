# hostKey: cortex-cuda's own SSH host key (also its agenix identity): decrypted by cortex into
# hostKeyShare, mounted read-only in the guest at hostKeyDir (den hosts/_cortex-cuda-host-key.nix).
{ ... }:
{
  ren.helpers.hostKey = {
    hostKeyShare = "/var/lib/microvms/cortex-cuda/host-key";
    hostKeyDir = "/etc/ssh/host-key";
  };
}
