# Cluster age/sops secrets: agenix-rekey-to-sops bridge + per-cluster sops/rekey storage, on every cluster.
{ ren, inputs, ... }:
{
  ren.aspects.k8s-secrets-cluster-age = {
    at = ren.kinds.cluster;
    k8s-manifests =
      { cluster, environment, fleet, ... }:
      {
        imports = [
          inputs.agenix-rekey-to-sops.sopsModules.default
          # Custom agenix-rekey generator types (standalone NixOS module)
          (import ../../secrets/_generators-module.nix)
        ];

        age = {
          sops.outputDir = cluster.secretPath + "/sops";
          rekey = {
            recipientIdentifier = "${environment.name}-${cluster.name}";
            storageMode = "local";
            generatedSecretsDir = cluster.secretPath + "/generated";
            localStorageDir = cluster.secretPath + "/rekeyed";
            inherit (fleet.secretsConfig) masterIdentities;
          };
        };
      };
  };
}
