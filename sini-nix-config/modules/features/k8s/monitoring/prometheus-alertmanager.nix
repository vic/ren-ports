# kube-prometheus-stack alertmanager values. Same aspect as prometheus.nix.
{ ren, ... }:
{
  ren.aspects.k8s-monitoring-prometheus.k8s-manifests =
    { cluster, environment, ... }:
    {
      applications.kube-prometheus-stack.helm.releases.kube-prometheus-stack.values.alertmanager = {
        enabled = true;
        alertmanagerSpec.externalUrl = "https://${ren.helpers.clusterDomainFor cluster "alertmanager"}";
        # Mail goes through the cluster's Postfix relay to Proton
        # (communication/smtp-relay.nix), which accepts in-cluster
        # senders from the environment's domain without auth.
        # Replaces the chart's default config, so its inhibit rules
        # are restated here.
        config = {
          global = {
            resolve_timeout = "5m";
            smtp_smarthost = "smtp.${environment.email.domain}:587";
            smtp_from = "alertmanager@${environment.email.domain}";
            smtp_require_tls = true;
          };
          route = {
            receiver = "email";
            group_by = [
              "namespace"
              "alertname"
            ];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "12h";
            routes = [
              # Always firing by design: proves the pipeline is alive,
              # never a page.
              {
                receiver = "null";
                matchers = [ ''alertname = "Watchdog"'' ];
              }
              {
                receiver = "null";
                matchers = [ ''alertname = "InfoInhibitor"'' ];
              }
              # Informational alerts stay visible in Alertmanager only.
              {
                receiver = "null";
                matchers = [ ''severity = "info"'' ];
              }
            ];
          };
          inhibit_rules = [
            {
              source_matchers = [ "severity = critical" ];
              target_matchers = [ "severity =~ warning|info" ];
              equal = [
                "namespace"
                "alertname"
                "instance"
              ];
            }
            {
              source_matchers = [ "severity = warning" ];
              target_matchers = [ "severity = info" ];
              equal = [
                "namespace"
                "alertname"
                "instance"
              ];
            }
            {
              source_matchers = [ "alertname = InfoInhibitor" ];
              target_matchers = [ "severity = info" ];
              equal = [
                "namespace"
                "instance"
              ];
            }
            { target_matchers = [ "alertname = InfoInhibitor" ]; }
            # Nothing reaches the cluster: every host looks silent.
            {
              source_matchers = [ "alertname = IngestDown" ];
              target_matchers = [ "alertname = HostSilent" ];
            }
          ];
          receivers = [
            { name = "null"; }
            {
              name = "email";
              email_configs = [
                {
                  to = environment.email.adminEmail;
                  send_resolved = true;
                }
              ];
            }
          ];
          templates = [ "/etc/alertmanager/config/*.tmpl" ];
        };
      };
    };
}
