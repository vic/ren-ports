# helm-charts: charts/ metadata + downloaded chart derivations (haumea over ./charts).
{ ren, inputs, ... }:
let
  load = inputs.haumea.lib.load;
  lift = inputs.haumea.lib.transformers.liftDefault;
  mkCharts =
    pkgs:
    let
      kubelib = inputs.nix-kube-generators.lib { inherit pkgs; };
    in
    load {
      src = ../../charts;
      loader = _: p: kubelib.downloadHelmChart (removeAttrs (import p) [ "bogusVersion" ]);
      transformer = lift;
    };
in
{
  ren.aspects.flake-helm-charts = {
    at = ren.kinds.fleet;
    flake = {
      chartsMetadata = load {
        src = ../../charts;
        transformer = lift;
      };
      charts = mkCharts;
    };
  };

  # downloaded chart derivations per system (sini chartsDerivations), read by platforms/k8s.nix
  ren.aspects.flake-helm-charts-derivations = {
    at = ren.kinds.system;
    chartsDerivations = { system, ... }: mkCharts system.legacyPackages;
  };
}
