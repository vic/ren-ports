# smtp-relay resources: header_checks table, upstream secret, TLS cert, CNPs.
_:
{
  ren.aspects.k8s-communication-smtp-relay.k8s-manifests =
    { config, cluster, ... }:
    {
      applications.smtp-relay.helm.releases.smtp-relay.values.configMaps.tables.data.header_checks = ''
        /^From:[[:space:]]*(.*[^[:space:]])[[:space:]]*<[^>]*>[[:space:]]*$/ REPLACE From: $1 <${cluster.k8s-communication-smtp-relay.upstream.username}>
        /^From:[[:space:]]*[^<]*$/ REPLACE From: ${cluster.k8s-communication-smtp-relay.upstream.username}
      '';

      applications.smtp-relay.resources = {
        secrets.smtp-relay-upstream.stringData.password =
          config.age.secrets.smtp-relay-upstream-password.sopsRef;

        certificates.smtp-relay.spec = {
          secretName = "smtp-relay-tls";
          issuerRef = {
            name = "${cluster.k8s-communication-smtp-relay.issuer}-issuer";
            kind = "ClusterIssuer";
          };
          dnsNames = [ cluster.k8s-communication-smtp-relay.hostname ];
        };

        ciliumNetworkPolicies = {
          allow-submission-ingress-smtp-relay.spec = {
            description = "Allow private-network clients to submit mail to the relay.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "smtp-relay";
            ingress = [
              {
                fromCIDR = [ "10.0.0.0/8" ];
                toPorts = [
                  {
                    ports = [
                      {
                        port = "587";
                        protocol = "TCP";
                      }
                    ];
                  }
                ];
              }
              {
                fromEntities = [ "cluster" ];
                toPorts = [
                  {
                    ports = [
                      {
                        port = "587";
                        protocol = "TCP";
                      }
                    ];
                  }
                ];
              }
            ];
          };

          allow-upstream-egress-smtp-relay.spec = {
            description = "Allow smtp-relay to submit to its upstream.";
            endpointSelector.matchLabels."app.kubernetes.io/name" = "smtp-relay";
            egress = [
              {
                toEntities = [ "world" ];
                toPorts = [
                  {
                    ports = [
                      {
                        port = toString cluster.k8s-communication-smtp-relay.upstream.port;
                        protocol = "TCP";
                      }
                    ];
                  }
                ];
              }
            ];
          };
        };
      };
    };
}
