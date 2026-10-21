# k8s-manifests class: per-cluster nixidy environment -> nixidyEnvs.<system>.<cluster> (den policies/clusters.nix cluster-to-nixidy).
{ ren, lib, inputs, ... }:
let
  # den looped lib.unique config.systems; here the linux `system` instances (nixidy rejects darwin hostPlatform)
  systems = lib.filter (lib.hasSuffix "-linux") (lib.attrNames ren.system);
  envFor =
    cluster: ms: system:
    inputs.nixidy.lib.mkEnv {
      # the system's pkgs (repo overlays) + pkgs.local (flake-pkgs-overlay), as den's flake overlays.default
      pkgs = ren.system.${system}.legacyPackages.extend (_: _: { local = inputs.self.packages.${system}; });
      # per-org merge so a local chart extends an upstream org instead of shadowing it
      charts =
        let
          upstream = inputs.nixhelm.chartsDerivations.${system} or { };
          local = inputs.self.chartsDerivations.${system} or { };
        in
        upstream // lib.mapAttrs (org: orgCharts: (upstream.${org} or { }) // orgCharts) local;
      # pinned OCI image refs as the `images` module arg (flake/oci-images.nix emits one system-independent attrset)
      extraSpecialArgs = { inherit inputs system; images = inputs.self.imageRefs; };
      modules = ms;
    };
in
{
  ren.classes.k8s-manifests = {
    at = ren.kinds.cluster;
    into =
      { cluster, ... }:
      ms: {
        nixidyEnvs = lib.genAttrs systems (system: {
          ${cluster.name} = envFor cluster ms system;
        });
      };
  };
}
