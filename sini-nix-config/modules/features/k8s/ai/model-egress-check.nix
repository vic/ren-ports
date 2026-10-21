# model-egress-check: only the allow-listed service accounts of
# model-egress.nix reach the cortex-cuda model ports, asserted over the
# committed render (nixidy-sync keeps it current).
#   nix build .#checks.x86_64-linux.model-egress
{ ren, ... }:
let
  rendered = ../../../../generated/manifests/prod-axon;
in
{
  ren.aspects.k8s-ai-model-egress-check = {
    at = ren.system.x86_64-linux;
    checks =
      { pkgs, ... }:
      {
        drvs.model-egress =
      pkgs.runCommand "model-egress"
        { nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.pyyaml ])) ]; }
        ''
          python3 -I ${./_checks/model-egress-check.py} ${rendered}
          touch $out
        '';
      };
  };
}
