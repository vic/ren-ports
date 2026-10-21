# qBittorrent VPN: gluetun WireGuard native sidecar (restartPolicy=Always initContainer, so the
# kubelet holds `main` until the tunnel is up) and the /dev/net/tun mount. Kill-switch: gluetun's
# firewall is primary; the CNPs in qbittorrent-net.nix are the second layer. Secrets: qbittorrent-vpn-secrets.nix.
{ ... }:
{
  ren.aspects.k8s-media-qbittorrent = {
    k8s-manifests =
      { images, ... }:
      {
        applications.qbittorrent = {
          helm.releases.qbittorrent.values = {
            controllers.main.initContainers.gluetun = {
              image = {
                inherit (images."qmcgaw/gluetun") repository digest;
              };
              restartPolicy = "Always";
              securityContext.capabilities.add = [ "NET_ADMIN" ];
              # Gate `main` on the tunnel: gluetun's health server returns 200 only once the VPN
              # loop is up. The kubelet dials the POD IP, so it must bind beyond loopback
              # (HEALTH_SERVER_ADDRESS) and the firewall must accept 9999 on eth0.
              probes.readiness = {
                enabled = true;
                type = "HTTP";
                path = "/";
                port = 9999;
                spec = {
                  initialDelaySeconds = 5;
                  periodSeconds = 10;
                  failureThreshold = 30;
                };
              };
              env = {
                VPN_SERVICE_PROVIDER = "custom";
                VPN_TYPE = "wireguard";

                WIREGUARD_PRIVATE_KEY.valueFrom.secretKeyRef = {
                  name = "media-vpn";
                  key = "private-key";
                };
                WIREGUARD_ADDRESSES.valueFrom.secretKeyRef = {
                  name = "media-vpn";
                  key = "addresses";
                };
                WIREGUARD_PUBLIC_KEY.valueFrom.secretKeyRef = {
                  name = "media-vpn";
                  key = "peer-public-key";
                };
                WIREGUARD_ENDPOINT_IP.valueFrom.secretKeyRef = {
                  name = "media-vpn";
                  key = "endpoint-ip";
                };
                WIREGUARD_ENDPOINT_PORT.valueFrom.secretKeyRef = {
                  name = "media-vpn";
                  key = "endpoint-port";
                };

                # Permit egress to the cluster pod/service CIDRs and the management VLAN so the
                # gateway ingress, *arr API callbacks and in-cluster DNS work through the kill-switch.
                FIREWALL_OUTBOUND_SUBNETS = "172.20.0.0/16,172.21.0.0/16,10.10.10.0/24";

                # INBOUND: gluetun's INPUT policy is DROP and its local-subnet auto-detection breaks
                # on Cilium's pod netns shape (/32 pod IP, node router gateway), so envoy, kubelet
                # probes and the *arrs all hit DROP. FIREWALL_INPUT_PORTS adds eth0-scoped accepts
                # (never tun0): 8080 qbt WebUI, 9999 health probe, 9710 qbittorrent-exporter metrics.
                FIREWALL_INPUT_PORTS = "8080,9999,9710";
                # Health server defaults to 127.0.0.1:9999, unreachable for the kubelet pod-IP probe.
                HEALTH_SERVER_ADDRESS = ":9999";

                # Forwarded port is read off gluetun's control server by the port-sync sidecar; no
                # up-command (app-template's tpl rejects gluetun's {{PORTS}} placeholder).
                VPN_PORT_FORWARDING = "on";
                VPN_PORT_FORWARDING_PROVIDER = "protonvpn";
              };
            };

            # Opens only the read-only forwarded-port route (auth=none); :8000 is not in
            # FIREWALL_INPUT_PORTS, so only the pod's own loopback can reach it.
            configMaps.gluetun-auth.data."config.toml" = ''
              [[roles]]
              name = "port-sync"
              routes = ["GET /v1/portforward"]
              auth = "none"
            '';

            persistence = {
              gluetun-auth = {
                type = "configMap";
                identifier = "gluetun-auth";
                advancedMounts.main.gluetun = [
                  {
                    path = "/gluetun/auth/config.toml";
                    subPath = "config.toml";
                    readOnly = true;
                  }
                ];
              };
              # /dev/net/tun char device, mounted into the gluetun container only.
              tun = {
                type = "hostPath";
                hostPath = "/dev/net/tun";
                hostPathType = "CharDevice";
                advancedMounts.main.gluetun = [ { path = "/dev/net/tun"; } ];
              };
            };
          };
        };
      };
  };
}
