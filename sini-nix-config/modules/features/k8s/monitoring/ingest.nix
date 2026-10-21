# Monitoring ingest - the cluster's write endpoint for everything outside it.
#
# Hosts push (Alloy) instead of the cluster scraping them, so hosts need no
# inbound rules and hosts the cluster cannot dial still report. An nginx
# proxy on a private LoadBalancer terminates TLS (ingest.<domain>), checks
# basic auth, and forwards exactly two requests:
#   POST /api/v1/write       -> Prometheus remote-write
#   POST /loki/api/v1/push   -> Loki push
# Everything else is 404: Prometheus serves its query and admin (delete) APIs
# on the same port, and none of that leaves the cluster.
#
# The password (ingest-password) is shared with the hosts' Alloy via the same
# rekeyFile; the proxy only holds its bcrypt htpasswd. Secrets resources, cert
# and CNP live in ingest-resources.nix (same aspect).
{ ... }:
let
  ingestUser = "ingest";
in
{
  ren.aspects.k8s-monitoring-ingest = {
    # Announced to hosts (monitoring-ingest channel); an environment picks a
    # cluster's endpoint with environment.monitoring.ingest. The password's
    # rekeyFile travels with it, so hosts in another environment use this
    # cluster's secret, not one under their own secretPath.
    monitoring-ingest =
      { cluster, environment, ... }:
      {
        cluster = cluster.name;
        url = "https://ingest.${environment.domain}";
        username = ingestUser;
        passwordFile = environment.secretPath + "/monitoring/ingest-password.age";
      };

    age-secrets =
      { environment, ... }:
      {
        imports = [
          ({ config, ... }: {
        age.secrets = {
          monitoring-ingest-password = {
            rekeyFile = environment.secretPath + "/monitoring/ingest-password.age";
            generator.script = "passphrase";
          };
          monitoring-ingest-htpasswd = {
            rekeyFile = environment.secretPath + "/monitoring/ingest-htpasswd.age";
            generator = {
              script = "htpasswd";
              dependencies = [ config.age.secrets.monitoring-ingest-password ];
            };
            settings.username = ingestUser;
            sopsOutput = {
              file = "monitoring";
              key = "ingest-htpasswd";
            };
          };
        };
          })
        ];
      };
  };
}
