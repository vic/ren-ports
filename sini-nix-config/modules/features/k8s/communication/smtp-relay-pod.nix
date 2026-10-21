# smtp-relay pod: Postfix deployment, LoadBalancer service, spool and TLS mounts.
{ ren, lib, ... }:
{
  ren.aspects.k8s-communication-smtp-relay.k8s-manifests =
    {
      cluster,
      charts,
      images,
      ...
    }:
    {
      applications.smtp-relay = {
        namespace = "mail";

        helm.releases.smtp-relay = {
          chart = charts.bjw-s-labs.app-template;
          values = {
            # The image applies every POSTFIX_* variable as a postconf setting;
            # service links would inject Kubernetes ones.
            defaultPodOptions.enableServiceLinks = false;

            controllers.main = {
              type = "deployment";
              # One instance: a second would hold a separate queue.
              strategy = "Recreate";
              containers.main = {
                image = {
                  inherit (images."boky/postfix") repository digest;
                };
                # supervisord outlives a postfix that failed to start; the
                # listener is the real liveness signal.
                probes = lib.genAttrs [ "liveness" "readiness" ] (_: {
                  enabled = true;
                  custom = true;
                  spec = {
                    tcpSocket.port = 587;
                    initialDelaySeconds = 15;
                  };
                });
                env = {
                  TZ = "America/Los_Angeles";
                  LOG_FORMAT = "json";
                  POSTFIX_myhostname = cluster.k8s-communication-smtp-relay.hostname;
                  POSTFIX_mynetworks = "127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
                  ALLOWED_SENDER_DOMAINS = cluster.k8s-communication-smtp-relay.domain;
                  POSTFIX_message_size_limit = "26214400";

                  RELAYHOST = "[${cluster.k8s-communication-smtp-relay.upstream.host}]:${toString cluster.k8s-communication-smtp-relay.upstream.port}";
                  RELAYHOST_USERNAME = cluster.k8s-communication-smtp-relay.upstream.username;
                  RELAYHOST_PASSWORD.valueFrom.secretKeyRef = {
                    name = "smtp-relay-upstream";
                    key = "password";
                  };
                  POSTFIX_smtp_tls_security_level = "secure";

                  POSTFIX_smtpd_tls_security_level = "encrypt";
                  POSTFIX_smtpd_tls_cert_file = "/tls/tls.crt";
                  POSTFIX_smtpd_tls_key_file = "/tls/tls.key";

                  POSTFIX_sender_canonical_maps = "static:${cluster.k8s-communication-smtp-relay.upstream.username}";
                  POSTFIX_sender_canonical_classes = "envelope_sender";
                  POSTFIX_header_checks = "regexp:/etc/postfix-tables/header_checks";
                };
              };
            };

            service.main = {
              controller = "main";
              type = "LoadBalancer";
              externalTrafficPolicy = "Local";
              annotations."lbipam.cilium.io/ips" = ren.helpers.getAssignment cluster "smtp-relay-internal";
              ports.submission.port = 587;
            };
          };
        };
      };
    };
}
