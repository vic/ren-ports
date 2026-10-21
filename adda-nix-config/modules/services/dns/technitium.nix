# services: technitium DNS resolver
{ ren, ... }:
{
  ren.aspects.services-dns-technitium.nixos =
    { lib, ... }:
    {
      # Technitium has no declarative NixOS settings — forwarders, DNSSEC, the
      #  rohu-ling.ts.net conditional forwarder, and blocklists all live in
      #  mutable state configured once through its web UI after first boot.
      services.technitium-dns-server.enable = true;

      # resolved's stub listener (127.0.0.53:53) blocks Technitium's own :53 bind
      #  (TCP wildcard binds conflict with an existing specific-address listener).
      services.resolved.enable = lib.mkForce false;

      # Reachable over the tailnet only, not the LAN/WAN-facing interface.
      networking.firewall.interfaces."tailscale0" = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [
          53
          5380 # web UI (HTTP)
          53443 # web UI (HTTPS)
        ];
      };
    };
}
