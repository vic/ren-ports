# K3s cluster bootstrap: oneshot systemd units that apply the generated manifests in dependency
# order on the initial node.
#   Wave -2: Cilium CNI + CoreDNS (networking first)  [this file]
#   Wave -1: SOPS secrets operator + cert-manager (bootstrap-sops.nix), then ArgoCD (bootstrap-argocd.nix)
# Sub-aspect of svc-k3s (which includes it). Helpers in _bootstrap-lib.nix.
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.svc-k3s-bootstrap.nixos =
    { k3s-nodes, pkgs, host, environment, ... }:
    let
      b = import ./_bootstrap-lib.nix { inherit lib inputs pkgs host k3s-nodes environment; };
    in
    {
      systemd.services.k3s-bootstrap-cilium = lib.mkIf b.shouldInit {
        description = "Bootstrap Cilium CNI and CoreDNS";
        after = [ "k3s.service" ];
        requires = [ "k3s.service" ];
        path = [
          pkgs.kubectl
          pkgs.cilium-cli
        ];
        environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "k3s-bootstrap-cilium" ''
            set -e

            echo "Waiting for k3s API server..."
            until kubectl get nodes; do
              sleep 5
            done

            if ${lib.getExe pkgs.cilium-cli} --kubeconfig $KUBECONFIG status >/dev/null 2>&1; then
              echo "Cilium already installed."
              exit 0
            fi

            echo "Applying bootstrap resources..."
            ${b.apply} -f ${b.manifestPath "bootstrap"} || true

            echo "Applying Cilium manifests..."
            ${b.apply} -f ${b.manifestPath "cilium"} || true
            sleep 30

            echo "Applying CoreDNS manifests..."
            ${b.apply} -f ${b.manifestPath "coredns"} || true
            sleep 30
          '';
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
