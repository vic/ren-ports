# Names, paths and container fragments shared across the genie-guard pod files.
rec {
  namespace = "genie";
  name = "genie-guard";
  uid = 65532;
  issuer = "xmsg-cluster-ca";
  runtimeDir = "/run/user";
  tlsDir = "/etc/xmsg/tls";
  peersDir = "/etc/xmsg/peers";
  stateDir = "/var/lib/xmsg";
  keyDir = "/etc/genie-guard";

  identity = "spiffe://json64.dev/ns/${namespace}/sa/${name}";
  ref = image: "${image.repository}@${image.digest}";

  hardened = {
    runAsUser = uid;
    runAsGroup = uid;
    runAsNonRoot = true;
    readOnlyRootFilesystem = true;
    allowPrivilegeEscalation = false;
    capabilities.drop = [ "ALL" ];
  };

  runMount = {
    name = "run";
    mountPath = runtimeDir;
  };
  # The root is read-only; a writable /tmp keeps the guard's runtime from
  # failing at start.
  tmpMount = {
    name = "tmp";
    mountPath = "/tmp";
  };
}
