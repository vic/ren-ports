# K3s bootstrap wave -1: ArgoCD (depends on SOPS for secret decryption). See bootstrap.nix.
{ lib, inputs, ... }:
{
  ren.aspects.svc-k3s-bootstrap.nixos =
    { k3s-nodes, pkgs, host, environment, ... }:
    let
      b = import ./_bootstrap-lib.nix { inherit lib inputs pkgs host k3s-nodes environment; };
    in
    {
      systemd.services.k3s-install-argocd = lib.mkIf b.shouldInit {
        description = "Bootstrap ArgoCD";
        after = [
          "k3s.service"
          "k3s-bootstrap-cilium.service"
          "k3s-install-sops-secrets-operator.service"
        ];
        requires = [
          "k3s.service"
          "k3s-bootstrap-cilium.service"
          "k3s-install-sops-secrets-operator.service"
        ];
        path = [ pkgs.kubectl ];
        environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "k3s-install-argocd" ''
            set -e

            echo "Waiting for k3s API server..."
            until kubectl get nodes; do
              sleep 5
            done

            if ! ${b.kubectl} get namespace argocd >/dev/null 2>&1; then
              ${b.kubectl} create namespace argocd
            fi

            if ! ${b.kubectl} get deployment -n argocd argocd-server >/dev/null 2>&1; then
              ${b.apply} -f ${b.manifestPath "argocd"}
              ${b.apply} -f ${b.manifestPath "bootstrap.yaml"}
            fi
          '';
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
