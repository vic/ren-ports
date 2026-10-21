# K3s bootstrap wave -1: SOPS secrets operator + cert-manager. See bootstrap.nix.
{ lib, inputs, ... }:
{
  ren.aspects.svc-k3s-bootstrap.nixos =
    { k3s-nodes, config, pkgs, host, environment, ... }:
    let
      b = import ./_bootstrap-lib.nix { inherit lib inputs pkgs host k3s-nodes environment; };
    in
    {
      systemd.services.k3s-install-sops-secrets-operator = lib.mkIf b.shouldInit {
        description = "Bootstrap SOPS secrets operator and cert-manager";
        after = [
          "k3s.service"
          "k3s-bootstrap-cilium.service"
        ];
        requires = [
          "k3s.service"
          "k3s-bootstrap-cilium.service"
        ];
        path = [ pkgs.kubectl ];
        environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "k3s-install-sops" ''
            set -e

            echo "Waiting for k3s API server..."
            until kubectl get nodes; do
              sleep 5
            done

            if ! ${b.kubectl} get namespace sops-secrets-operator >/dev/null 2>&1; then
              ${b.kubectl} create namespace sops-secrets-operator
            fi

            if ! ${b.kubectl} --namespace sops-secrets-operator get secret sops-age-key-file >/dev/null 2>&1; then
              ${b.kubectl} create secret generic sops-age-key-file \
                --namespace sops-secrets-operator \
                --from-file=key=${config.age.secrets.kubernetes-sops-age-key.path}
            fi

            if ! ${b.kubectl} get deployment -n sops-secrets-operator sops-sops-secrets-operator >/dev/null 2>&1; then
              ${b.apply} -f ${b.manifestPath "sops-secrets-operator"}
              sleep 30
            fi

            if ! ${b.kubectl} get deployment -n cert-manager cert-manager >/dev/null 2>&1; then
              ${b.apply} -f ${b.manifestPath "cert-manager"}
              sleep 30
            fi
          '';
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
