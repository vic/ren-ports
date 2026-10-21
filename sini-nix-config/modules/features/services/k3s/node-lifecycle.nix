# K3s node lifecycle, drain on shutdown, uncordon on startup. Sub-aspect of svc-k3s.
# One oneshot unit whose stop path is the drain: After=k3s.service makes ExecStop run to completion
# BEFORE systemd stops k3s; After=containerd.service keeps the runtime alive while pods terminate.
# Deliberately NO PartOf/BindsTo on k3s: a k3s restart (colmena activation) must not drain.
# Shutdown never stalls: the stop path skips the drain when no OTHER node is Ready and schedulable
# (whole-cluster poweroff or last node), since eviction cannot succeed there.
{ ... }:
{
  ren.aspects.svc-k3s-node-lifecycle.nixos =
    { config, pkgs, ... }:
    let
      nodeName = config.networking.hostName;
    in
    {
      systemd.services.k3s-node-lifecycle = {
        description = "K3s node lifecycle: uncordon after startup, drain before shutdown";
        wantedBy = [ "multi-user.target" ];
        after = [
          "k3s.service"
          "containerd.service"
        ];
        wants = [ "k3s.service" ];
        path = [
          pkgs.kubectl
          pkgs.jq
        ];
        environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = "10min";
          # Must exceed the drain --timeout below (90s) plus slack.
          TimeoutStopSec = "2min";

          ExecStart = pkgs.writeShellScript "k3s-node-uncordon" ''
            echo "Waiting for node ${nodeName} to be Ready..."
            until kubectl wait --for=condition=Ready "node/${nodeName}" --timeout=30s 2>/dev/null; do
              sleep 5
            done
            kubectl uncordon "${nodeName}"
          '';

          ExecStop = pkgs.writeShellScript "k3s-node-drain" ''
            # Never block shutdown on a broken control plane.
            if ! kubectl get node "${nodeName}" --request-timeout=10s >/dev/null 2>&1; then
              echo "apiserver unreachable; skipping drain"
              exit 0
            fi

            # Only drain when pods have somewhere to go: count OTHER Ready, schedulable nodes.
            schedulable_peers=$(
              kubectl get nodes -o json --request-timeout=10s 2>/dev/null \
                | jq -r --arg me "${nodeName}" '
                    [ .items[]
                      | select(.metadata.name != $me)
                      | select(.spec.unschedulable != true)
                      | select([ (.spec.taints // [])[] | select(.effect == "NoSchedule") ] | length == 0)
                      | select(any(.status.conditions[]; .type == "Ready" and .status == "True"))
                    ] | length' 2>/dev/null
            )
            if [ "''${schedulable_peers:-0}" -lt 1 ]; then
              echo "no schedulable peer node (whole-cluster shutdown / last node); skipping drain"
              exit 0
            fi

            echo "Draining ${nodeName} (''${schedulable_peers} schedulable peer(s))..."
            kubectl drain "${nodeName}" \
              --ignore-daemonsets \
              --delete-emptydir-data \
              --timeout=90s \
              || echo "drain incomplete (timeout or eviction failure); continuing shutdown"
            exit 0
          '';
        };
      };
    };
}
