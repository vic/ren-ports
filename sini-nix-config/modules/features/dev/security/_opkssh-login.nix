# `opkssh-login` wrapper: authenticate against kanidm. Our opkssh fork loads the
# freshly-minted cert into the ssh-agent named by SSH_AUTH_SOCK with a lifetime
# matching the token. SSH_AUTH_SOCK points at the standard agent, not the mux:
# the mux is a read-only aggregator that cannot accept key adds, and it re-reads
# the standard agent live, so the cert shows up through the mux immediately.
pkgs: lib: kanidmIssuer: standardSock:
pkgs.writeShellScript "opkssh-login" ''
  set -euo pipefail
  export SSH_AUTH_SOCK="${standardSock}"
  exec ${lib.getExe pkgs.opkssh} login --provider=${kanidmIssuer},opkssh "$@"
''
