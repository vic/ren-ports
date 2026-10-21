# nixidy battery crds bridge: `crds` channel pool (cluster -> cluster) built per cluster into nixidy values.
{ ren, inputs, ... }:
let
  # forward only present, non-empty keys
  pickNonEmpty =
    lib: keys: attrs:
    lib.filterAttrs (_: v: v != null && v != "" && v != { }) (
      builtins.intersectAttrs (lib.genAttrs keys (_: null)) attrs
    );
  typeKeys = [ "namePrefix" "attrNameOverrides" "skipCoerceToList" ];
  chartKeys = [ "chart" "chartAttrs" "values" "extraOpts" ];
  buildCrd =
    { lib, generators, kubeVersion }:
    spec:
    let
      typeOpts = pickNonEmpty lib typeKeys spec;
      kf = lib.optionalAttrs (spec ? crds) { kindFilter = spec.crds; };
      chartArgs = { inherit (spec) name; inherit kubeVersion; } // pickNonEmpty lib chartKeys spec;
    in
    if spec.chart or null != null || spec.chartAttrs or { } != { } then
      {
        module = generators.fromChartCRDModule (chartArgs // kf // typeOpts);
        # kindFilter must constrain bootstrap objects too, else ArgoCD blocks on RepeatedResourceWarning
        objects = generators.crdObjectsFromChart (chartArgs // kf);
      }
    else if spec.src or null != null then
      {
        module = generators.fromCRDModule ({ inherit (spec) name src; crdFiles = spec.crds; } // typeOpts);
        objects = generators.crdObjects { inherit (spec) src; crdFiles = spec.crds; };
      }
    else
      throw "a crds emission has neither 'src' nor 'chart'/'chartAttrs' set";
in
{
  ren.aspects.nixidy-crds = {
    at = ren.kinds.cluster;
    k8s-manifests =
      { crds, cluster, pkgs, lib, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        built = map (buildCrd {
          inherit lib;
          generators = inputs.nixidy.packages.${system}.generators;
          kubeVersion = "v${cluster.kubeVersion or pkgs.kubernetes.version}";
        }) crds;
      in
      {
        nixidy.applicationImports = map (b: b.module) built;
        applications.bootstrap.objects = lib.concatMap (b: b.objects) built;
      };
  };
  # `crds` is a content formal: every channel pool is bound at every scope, empty when nothing was emitted (ren/lib/pipeline-args.nix:21).
}
