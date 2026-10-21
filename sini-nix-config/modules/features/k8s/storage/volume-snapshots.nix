# Volume Snapshots - VolumeSnapshotClass CRDs for CSI snapshot support.
{ ... }:
{
  ren.aspects.k8s-storage-volume-snapshots.crds =
    { pkgs, lib, ... }:
    let
      src = pkgs.fetchFromGitHub {
        owner = "kubernetes-csi";
        repo = "external-snapshotter";
        rev = "v8.5.0";
        hash = "sha256-D+9O6/EBpqaHrQ8mOZoXqjmR/1WfK3BoxuvAYzW7bIE=";
      };
      path = "client/config/crd";
      crds = lib.pipe (builtins.readDir "${src}/${path}") [
        (lib.filterAttrs (_name: type: type == "regular"))
        (lib.filterAttrs (name: _type: lib.hasSuffix ".yaml" name))
        builtins.attrNames
        (map (file: "${path}/${file}"))
      ];
    in
    {
      name = "volume-snapshots";
      inherit src crds;
    };
}
