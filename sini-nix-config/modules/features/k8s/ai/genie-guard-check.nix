# genie-guard-check: the hardening, identity, egress and shared-socket properties
# of genie-guard.nix, asserted over its manifests with the flag forced on and the
# pinned images, so the check holds whatever axon's flag is.
#   nix build .#checks.x86_64-linux.genie-guard-pod
{ ren, lib, ... }:
let
  # A Ren aspect is not callable and imageRefs is not readable from content, so
  # the pure builder is called with refs read from images/ directly (path literal).
  imageRef =
    ns: n:
    let
      a = import (../../../../images + "/${ns}/${n}/default.nix");
    in
    {
      repository = a.imageName;
      digest = a.imageDigest;
    };
  manifests = import ./_genie-guard-manifests.nix { inherit ren lib; } {
    config.age.secrets.genie-guard-api-key.sopsRef = "ref+sops://stand-in";
    cluster = {
      name = "axon";
      k8s-ai-genie-guard = {
        enable = true;
        hub = "bitstream";
        devHubs = [ ];
      };
    };
    images = {
      "sini/xmsg" = imageRef "sini" "xmsg";
      "sini/genie-guard" = imageRef "sini" "genie-guard";
    };
  };
in
{
  ren.aspects.k8s-ai-genie-guard-check = {
    at = ren.system.x86_64-linux;
    checks =
      { pkgs, ... }:
      {
        drvs.genie-guard-pod = pkgs.runCommand "genie-guard-pod" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          python3 -I ${./_checks/genie-guard-check.py} ${pkgs.writeText "genie-guard.json" (builtins.toJSON manifests)}
          touch $out
        '';
      };
  };
}
