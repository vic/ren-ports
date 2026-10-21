# port-sync sidecar: polls gluetun's control server (:8000/v1/portforward) for the ProtonVPN forwarded
# port every 60s and, when it changes, POSTs qBittorrent's listen port via the WebUI API (shared pod
# loopback, busybox wget; unauthenticated thanks to the seeded LocalHostAuth=false). The same call pins
# qbt to tun0 (current_network_interface): unpinned, libtorrent binds eth0's pod IP, whose packets
# leave via eth0 and are dropped by the kill-switch (0 DHT nodes, magnets stuck in metaDL).
# Nix indented string: busybox shell `$var` refs are escaped as `''${var}`.
{ ... }:
{
  ren.aspects.k8s-media-qbittorrent.k8s-manifests =
    { images, ... }:
    {
      applications.qbittorrent.helm.releases.qbittorrent.values.controllers.main.containers.port-sync = {
        image = {
          inherit (images."library/busybox") repository digest;
        };
        command = [
          "/bin/sh"
          "-c"
          ''
            set -eu
            GTN=http://127.0.0.1:8000/v1/portforward
            QBT=http://127.0.0.1:8080
            last=""
            while true; do
              # Compact-JSON assumption: gluetun's control server emits a single-line
              # object like {"port":12345}; this sed grabs the first "port":<digits>. If
              # gluetun ever pretty-prints the response, this extraction must change.
              port="$(wget -qO- "$GTN" 2>/dev/null | sed -n 's/.*"port":\([0-9]*\).*/\1/p' || true)"
              if [ -z "''${port:-}" ] || [ "''${port}" = "0" ]; then
                echo "port-sync: no forwarded port from gluetun control server"
              elif [ "''${port}" = "''${last}" ]; then
                : # steady state: port unchanged, nothing to push — stay quiet
              else
                echo "port-sync: setting qBittorrent listen port to ''${port}"
                if wget -qO- --post-data "json={\"listen_port\":''${port},\"current_network_interface\":\"tun0\"}" \
                    "$QBT/api/v2/app/setPreferences" >/dev/null 2>&1; then
                  last="''${port}"
                else
                  echo "port-sync: setPreferences failed (qBittorrent not ready?), will retry"
                fi
              fi
              sleep 60
            done
          ''
        ];
      };
    };
}
