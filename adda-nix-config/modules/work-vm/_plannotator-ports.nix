# The loopback port plannotator's review UI binds on each work VM, and therefore the
#  port the laptop forwards to it (modules/users/adda/ssh.nix). One attrset for both
#  ends so the two cannot drift apart.
# They must differ per host: the forwards are set up from the same laptop, and two
#  sessions asking for the same local bind port give
#  "bind [127.0.0.1]:19432: Address already in use" on the second one — the forward
#  then silently belongs to the first host's session.
# 19432 is plannotator's own DEFAULT_REMOTE_PORT (packages/server/remote.ts), used when
#  it detects an SSH session; PLANNOTATOR_PORT overrides it, which is how harena-nixos
#  gets a different one (modules/aspects/work-vm/default.nix).
{
  fabrica-nixos = 19432;
  harena-nixos = 19433;
}
