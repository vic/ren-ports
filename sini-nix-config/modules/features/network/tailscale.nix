# Tailscale mesh: joins the headscale control plane. Auth key comes from
# network-tailscale-age-secrets; the daemon runs in nftables mode.
{ ren, lib, ... }:
{
  ren.aspects.network-tailscale = {
    includes = with ren.aspects; [ network-tailscale-age-secrets ];

    nixos =
      { config, environment, host, ... }:
      lib.mkIf (builtins.pathExists (host.secretPath + "/tailscale-preauthkey.age")) {
        services.tailscale = {
          enable = true;
          openFirewall = true;
          authKeyFile = config.age.secrets.tailscale-auth-key.path;
          extraUpFlags = [
            "--login-server=https://${ren.helpers.domainFor environment "headscale"}"
          ];
          extraDaemonFlags = [ "--no-logs-no-support" ];
        };

        networking = {
          nftables.enable = true;
          firewall = {
            checkReversePath = "loose";
            trustedInterfaces = [ config.services.tailscale.interfaceName ];
            allowedUDPPorts = [ config.services.tailscale.port ];
          };
        };

        systemd.services.tailscaled.serviceConfig = {
          Environment = [ "TS_DEBUG_FIREWALL_MODE=nftables" ];
          # When its TUN device closes under it (networkd flushing its ip rules on
          # a switch), tailscaled exits 0, which on-failure does not restart.
          Restart = "always";
        };
      };

    persist.directories = [ "/var/lib/tailscale" ];
  };
}
