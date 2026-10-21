# HyperQwen image unpacked to a store rootfs + env file (see hyperqwen-service.nix).
{ pkgs }:
let
  image = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/syv-ai/hyperqwen";
    imageDigest = "sha256:f761ce93d19e6c5a5dfbfb36d8eb98bf7f52fd09cd456465ed14ffcc673b0ffe"; # sha-3acb93f
    finalImageTag = "sha-3acb93f";
    hash = "sha256-+N7uldVJiwpWoh2XOY9v//TCEBFzX6Kuvo8I65gKVCs=";
  };
  # rootfs/ plus the image's environment, which --rootfs does not apply.
  bundle =
    pkgs.runCommand "hyperqwen-bundle"
      {
        nativeBuildInputs = [
          pkgs.skopeo
          pkgs.python3
        ];
      }
      ''
        export HOME=$TMPDIR
        skopeo --insecure-policy copy docker-archive:${image} dir:$TMPDIR/img
        python3 ${./_assets/oci-unpack.py} $TMPDIR/img $out
      '';
in
bundle
