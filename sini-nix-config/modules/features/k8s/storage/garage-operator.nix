# Garage operator (rajsinghtech) - owns the GarageCluster StatefulSet/Services/
# garage.toml/PDB reconciliation and the six Garage* CRDs (GarageCluster,
# GarageNode, GarageBucket, GarageKey, GarageAdminToken, GarageReferenceGrant).
#
# CRDs are registered through the crds bridge (early sync-wave -1), and the
# controller chart's own CRD install is disabled so the bridge is the sole CRD
# owner - the cnpg precedent (cloudnative-pg.nix). The local chart is built in
# pkgs/charts (charts.rajsinghtech.garage-operator); the crds quirk has no
# `charts` arg, so it reaches the chart via inputs.self.chartsDerivations.
#
# Webhooks (admission + multi-version conversion) are DISABLED on both the CRD
# extraction and the release: the crds bridge runs `helm template` with no
# `--namespace`, so enabled conversion webhooks would bake the wrong namespace
# + a cert-manager Certificate that lives elsewhere. Disabled = clean,
# namespace-independent CRDs with the storage version served.
{ ... }:
{
  ren.aspects.k8s-storage-garage-operator = {
    # No kindFilter: register all six Garage* CRDs (templates/crds.yaml,
    # gated on crds.install, default true).
    crds =
      { inputs, system, ... }:
      {
        name = "garage-operator";
        chart = inputs.self.chartsDerivations.${system}.rajsinghtech.garage-operator;
        values.webhooks.enabled = false;
      };

    k8s-manifests =
      { charts, ... }:
      {
        applications.garage-operator = {
          namespace = "garage";

          # Operator + CRDs before any Garage* CR (the GarageCluster lives in the
          # `garage` app at the default wave 0).
          annotations."argocd.argoproj.io/sync-wave" = "-1";

          helm.releases.garage-operator = {
            chart = charts.rajsinghtech.garage-operator;
            values = {
              # CRDs are deployed via the bootstrap app (crds bridge), not the
              # operator chart, to keep them out of the helm release lifecycle.
              crds.install = false;
              # Single active reconciler; leader election stays on (chart default).
              replicaCount = 1;
              # Webhooks off - consistent with the conversion-stripped CRDs above.
              webhooks.enabled = false;
            };
          };
        };
      };
  };
}
