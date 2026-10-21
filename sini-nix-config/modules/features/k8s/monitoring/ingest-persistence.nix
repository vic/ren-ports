# monitoring-ingest mounts: nginx conf, htpasswd, TLS (same aspect as ingest.nix).
{ ... }:
let
  name = "monitoring-ingest";
in
{
  ren.aspects.k8s-monitoring-ingest.k8s-manifests.applications.${name}.helm.releases.${name}.values.persistence = {
    config = {
      type = "configMap";
      identifier = "config";
      globalMounts = [
        {
          path = "/etc/nginx/conf.d/default.conf";
          subPath = "default.conf";
          readOnly = true;
        }
      ];
    };
    auth = {
      type = "secret";
      name = "${name}-htpasswd";
      globalMounts = [
        {
          path = "/auth";
          readOnly = true;
        }
      ];
    };
    tls = {
      type = "secret";
      name = "${name}-tls";
      globalMounts = [
        {
          path = "/tls";
          readOnly = true;
        }
      ];
    };
  };
}
