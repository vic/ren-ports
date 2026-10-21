# The two containers of the genie-guard pod: the xmsg leaf and the guard.
{ images }:
let
  sh = import ./_genie-guard-shared.nix;
  xdg = {
    name = "XDG_RUNTIME_DIR";
    value = sh.runtimeDir;
  };
  ro = name: mountPath: {
    inherit name mountPath;
    readOnly = true;
  };
in
[
  {
    name = "xmsg";
    image = sh.ref images."sini/xmsg";
    args = [
      "serve"
      "--leaf"
      "--leaf-principal"
      sh.name
      # Required by --leaf; loopback in the pod's own netns.
      "--listen"
      "127.0.0.1:7787"
      "--leaf-register-sock"
      "${sh.runtimeDir}/xmsg/register.sock"
      "--db-path"
      "${sh.stateDir}/xmsg.db"
      "--peers-file"
      "${sh.peersDir}/peers.json"
      "--fed-cert"
      "${sh.tlsDir}/tls.crt"
      "--fed-key"
      "${sh.tlsDir}/tls.key"
    ];
    env = [ xdg ];
    securityContext = sh.hardened;
    volumeMounts = [
      sh.runMount
      sh.tmpMount
      {
        name = "state";
        mountPath = sh.stateDir;
      }
      (ro "tls" sh.tlsDir)
      (ro "peers" sh.peersDir)
    ];
  }
  {
    inherit (sh) name;
    image = sh.ref images."sini/genie-guard";
    env = [
      xdg
      {
        name = "GENIE_GUARD_NINFER_URL";
        valueFrom.secretKeyRef = {
          inherit (sh) name;
          key = "ninfer-url";
        };
      }
      {
        name = "GENIE_GUARD_API_KEY_FILE";
        value = "${sh.keyDir}/api-key";
      }
    ];
    securityContext = sh.hardened;
    volumeMounts = [
      sh.runMount
      sh.tmpMount
      (ro "api-key" sh.keyDir)
    ];
  }
]
