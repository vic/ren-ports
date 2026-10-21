# The cert-manager Certificate spec of genie-guard's xmsg identity.
let
  sh = import ./_genie-guard-shared.nix;
in
{
  secretName = "${sh.name}-xmsg-tls";
  issuerRef = {
    name = sh.issuer;
    kind = "ClusterIssuer";
    group = "cert-manager.io";
  };
  uris = [ sh.identity ];
  usages = [
    "digital signature"
    "key encipherment"
    "server auth"
    "client auth"
  ];
  # Short-lived: expiry stands in for revocation (plan §6.7).
  duration = "24h";
  renewBefore = "8h";
  privateKey = {
    algorithm = "ECDSA";
    size = 256;
    encoding = "PKCS8";
    rotationPolicy = "Always";
  };
}
