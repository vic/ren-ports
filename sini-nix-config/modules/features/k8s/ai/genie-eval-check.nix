# genie-eval-check: the RBAC, bounds and egress properties of genie-eval.nix,
# asserted over the committed render (nixidy-sync keeps it current).
#   nix build .#checks.x86_64-linux.genie-eval
{ ren, ... }:
let
  rendered = ../../../../generated/manifests/prod-axon;
in
{
  ren.aspects.k8s-ai-genie-eval-check = {
    at = ren.system.x86_64-linux;
    checks =
      { pkgs, ... }:
      {
        drvs.genie-eval =
      pkgs.runCommand "genie-eval"
        { nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.pyyaml ])) ]; }
        ''
          python3 -I ${./_checks/genie-eval-check.py} ${rendered + "/genie-eval"} \
            ${rendered + "/cilium/CiliumClusterwideNetworkPolicy-allow-internal-egress.yaml"} \
            ${rendered + "/coredns/Deployment-coredns.yaml"}
          touch $out
        '';
      };
  };
}
