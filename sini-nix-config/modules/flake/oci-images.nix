# oci-images: images/ metadata, pinned pullImage derivations, <ns>/<name> -> {repository; digest} refs.
{ ren, inputs, ... }:
let
  load = inputs.haumea.lib.load;
  lift = inputs.haumea.lib.transformers.liftDefault;
  lib = inputs.nixpkgs-unstable.lib;
  meta = load {
    src = ../../images;
    transformer = lift;
  };
  mkImages =
    pkgs:
    load {
      src = ../../images;
      loader =
        _: p:
        let
          a = import p;
        in
        pkgs.dockerTools.pullImage {
          inherit (a) imageName imageDigest;
          sha256 = a.imageHash;
          finalImageName = a.imageName;
          finalImageTag = a.imageTag;
        };
      transformer = lift;
    };
  refs = lib.foldlAttrs (
    acc: ns: names:
    acc
    // lib.mapAttrs' (n: m: lib.nameValuePair "${ns}/${n}" {
      repository = m.imageName;
      digest = m.imageDigest;
    }) names
  ) { } meta;
in
{
  ren.aspects.flake-oci-images = {
    at = ren.kinds.fleet;
    flake = {
      imagesMetadata = meta;
      images = mkImages;
      imageRefs = refs; # one system-independent attrset (platforms/k8s.nix reads inputs.self.imageRefs)
    };
  };

  # pinned pullImage derivations per system (sini imagesDerivations)
  ren.aspects.flake-oci-images-derivations = {
    at = ren.kinds.system;
    imagesDerivations = { system, ... }: mkImages system.legacyPackages;
  };
}
