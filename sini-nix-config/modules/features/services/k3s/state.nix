# K3s secrets (cluster token, SOPS age key, registry credential) and persisted state.
{ ren, lib, ... }:
{
  ren.aspects.svc-k3s = {
    # Cluster token (all nodes) + SOPS age key (always provisioned, but only used by bootstrap
    # services which are guarded by shouldInit)
    age-secrets =
      { host, environment, ... }:
      let
        cluster = ren.helpers.clusterOf host;
      in
      lib.optionalAttrs (cluster != null) {
        age.secrets.kubernetes-cluster-token = {
          rekeyFile = cluster.secretPath + "/cluster-token.age";
          generator.script = "passphrase";
        };

        age.secrets.kubernetes-sops-age-key = {
          rekeyFile = cluster.secretPath + "/cluster-sops-age-key.age";
          path = "/var/lib/sops/age/key.txt";
        };

        # Shared-rekeyFile registry credential: identical rekeyFile + generator to the registry
        # host's registry-password, so agenix-rekey produces the same cleartext on every node.
        # Consumed by k3s-registries-config to build registries.yaml.
        age.secrets.registry-password = {
          rekeyFile = environment.secretPath + "/registry/registry-password.age";
          generator.script = "rfc3986-secret";
        };
      };

    # Persist k3s and kubeconfig state across reboots
    persist.directories = [
      "/var/lib/rancher"
      "/var/lib/kubelet"
      "/etc/rancher"
    ];
  };
}
