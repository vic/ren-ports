# monitoring-ingest nginx proxy release (same aspect as ingest.nix).
{ ren, ... }:
let
  name = "monitoring-ingest";
in
{
  ren.aspects.k8s-monitoring-ingest.k8s-manifests =
    {
      cluster,
      charts,
      environment,
      images,
      ...
    }:
    let
      hostname = "ingest.${environment.domain}";
      upstream = svc: port: "http://${svc}.monitoring.svc.cluster.local:${toString port}";
      writeOnly = path: target: ''
        location = ${path} {
          limit_except POST { deny all; }
          auth_basic "monitoring ingest";
          auth_basic_user_file /auth/htpasswd;
          client_max_body_size 32m;
          proxy_pass ${target};
        }
      '';
      nginxConf = ''
        server {
          listen 8443 ssl;
          server_name ${hostname};
          ssl_certificate /tls/tls.crt;
          ssl_certificate_key /tls/tls.key;

          ${writeOnly "/api/v1/write" "${upstream "kube-prometheus-stack-prometheus" 9090}/api/v1/write"}
          ${writeOnly "/loki/api/v1/push" "${upstream "loki" 3100}/loki/api/v1/push"}
          location / { return 404; }
        }
      '';
    in
    {
      applications.${name} = {
        namespace = "monitoring";

        helm.releases.${name} = {
          chart = charts.bjw-s-labs.app-template;
          values = {
            controllers.main = {
              type = "deployment";
              containers.main = {
                image = {
                  inherit (images."library/nginx") repository digest;
                };
                probes = {
                  liveness = {
                    enabled = true;
                    custom = true;
                    spec.tcpSocket.port = 8443;
                  };
                  readiness = {
                    enabled = true;
                    custom = true;
                    spec.tcpSocket.port = 8443;
                  };
                };
              };
            };

            service.main = {
              controller = "main";
              type = "LoadBalancer";
              # Keep the client address, for the CIDR rule in ingest-resources.nix.
              externalTrafficPolicy = "Local";
              annotations."lbipam.cilium.io/ips" = ren.helpers.getAssignment cluster name;
              ports.https = {
                port = 443;
                targetPort = 8443;
              };
            };

            configMaps.config.data."default.conf" = nginxConf;

          };
        };
      };
    };
}
