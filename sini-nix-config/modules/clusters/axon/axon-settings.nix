# Cluster settings: one flat typed field per aspect on the cluster kind
# (fields declared in modules/features/k8s/*).
{ ... }:
{
  ren.cluster.axon = {
    # Coder bootstrap complete: first admin created, lock login to kanidm OIDC only.
    k8s-dev-coder.bootstrap = false;

    # xmsg cluster CA issuer for pod certificates (federation plan 6.7).
    k8s-security-cert-manager-xmsg-ca.enable = true;

    # genie-guard as an xmsg leaf pod of sini's xmsg on bitstream; also a leaf on cortex for dev.
    k8s-ai-genie-guard = {
      enable = true;
      devHubs = [ "cortex" ];
    };

    # Pin Cilium datapath to physical NICs; `enp+` excludes tailscale0.
    k8s-network-cilium.devices = "enp+";

    # RomM 100k-ROM first scan: 14-day timeout, more scan concurrency.
    k8s-media-romm-settings-scanTimeout = 14 * 24 * 60 * 60;
    k8s-media-romm-settings-scanWorkers = 10;

    # Postfix relay to Proton: all mail leaves as infra@json64.dev.
    k8s-communication-smtp-relay = {
      domain = "json64.dev";
      hostname = "smtp.json64.dev";
      issuer = "json64-dev";
      upstream = {
        host = "smtp.protonmail.ch";
        username = "infra@json64.dev";
        passwordSecret = "smtp-infra-at-json64-dev.age";
      };
    };
  };
}
