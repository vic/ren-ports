# SMTP relay: Postfix (boky/postfix) smarthosting to an upstream submission
# service for LAN and in-cluster senders. Identity and upstream are settings
# with no defaults: a cluster that includes the aspect states them.
#
# Clients submit on 587 with mandatory STARTTLS (a cert for hostname) and no
# auth: mynetworks is narrowed to RFC1918, the CNP to 10.0.0.0/8. Outbound is a
# verified-TLS SASL login as upstream.username. Providers such as Proton only
# accept mail from the token's own address, so the envelope sender is
# canonicalised to it and the From header is rewritten by header_checks (a
# canonical map on header_sender would also clobber Reply-To).
# ALLOWED_SENDER_DOMAINS checks the pre-rewrite envelope, so clients must still
# send from `domain`. The hostname needs a DNS record on the private LB IP.
# Options (den descriptions): domain = sender domain; hostname = myhostname and
# STARTTLS cert name (must resolve to the LB address); issuer = cert-manager
# stem, requested from `<issuer>-issuer`; upstream.passwordSecret = age file
# relative to the environment's secretPath, supplied by hand, no generator.
# Pod and manifests in smtp-relay-pod.nix, policies in smtp-relay-net.nix.
{ ren, lib, ... }:
let
  inherit (ren.lib) opt;
  t = lib.types;
in
{
  ren.kinds.cluster.k8s-communication-smtp-relay = opt (t.submodule {
    options = {
      domain = opt t.str null; # e.g. example.com
      hostname = opt t.str null; # e.g. smtp.example.com
      issuer = opt t.str null; # e.g. example-com
      upstream = opt (t.submodule {
        options = {
          host = opt t.str null;
          port = opt t.port 587;
          username = opt t.str null; # e.g. infra@example.com
          passwordSecret = opt t.str null; # e.g. smtp-infra-at-example-com.age
        };
      }) { };
    };
  }) { };

  ren.aspects.k8s-communication-smtp-relay = {
    service-domains = [ ];

    age-secrets =
      { cluster, environment, ... }:
      {
        age.secrets.smtp-relay-upstream-password = {
          rekeyFile =
            environment.secretPath + "/${cluster.k8s-communication-smtp-relay.upstream.passwordSecret}";
          sopsOutput = {
            file = "smtp";
            key = "upstream-password";
          };
        };
      };

    k8s-manifests = { ... }: {
      applications.smtp-relay.helm.releases.smtp-relay.values.persistence = {
        tables = {
          type = "configMap";
          identifier = "tables";
          globalMounts = [
            {
              path = "/etc/postfix-tables";
              readOnly = true;
            }
          ];
        };
        tls = {
          type = "secret";
          name = "smtp-relay-tls";
          globalMounts = [
            {
              path = "/tls";
              readOnly = true;
            }
          ];
        };
        spool = {
          type = "persistentVolumeClaim";
          accessMode = "ReadWriteOnce";
          size = "1Gi";
          storageClass = "longhorn";
          globalMounts = [ { path = "/var/spool/postfix"; } ];
        };
      };
    };
  };
}
