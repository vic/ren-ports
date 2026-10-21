# services: pihole DNS resolver
{ ren, ... }:
{
  ren.aspects.services-dns-pihole.nixos =
    { fleet, lib, ... }:
    {
      # resolved's stub listener (127.0.0.53:53) blocks pihole-ftl's own :53 bind
      #  (TCP wildcard binds conflict with an existing specific-address listener).
      services.resolved.enable = lib.mkForce false;

      # pihole-ftl (a dnsmasq fork) can't speak DoH/DoT/DoQ itself, so encrypted
      #  upstream resolution is delegated to a local dnsproxy instance it forwards to.
      services.dnsproxy = {
        enable = true;
        settings = {
          listen-addrs = [ "127.0.0.1" ];
          listen-ports = [ 5053 ];
          bootstrap = fleet.plainDns;
          upstream = fleet.upstreamDns;
        };
      };

      services.pihole-ftl = {
        enable = true;
        lists = [
          {
            url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
            description = "Steven Black's unified hosts";
          }
          {
            url = "https://big.oisd.nl/";
            description = "OISD Big";
          }
          {
            url = "https://filters.adtidy.org/extension/chromium/filters/3.txt";
            description = "AdGuard Tracking Protection filter";
          }
          {
            url = "https://easylist.to/easylist/easyprivacy.txt";
            description = "EasyPrivacy";
          }
        ];
        settings = {
          dns.upstreams = [ "127.0.0.1#5053" ];
          # The tailnet domain is carved out to Tailscale's own resolver so tailnet
          #  names keep resolving; dnsproxy above only handles the general case.
          misc.dnsmasq_lines = [
            "server=/${fleet.tailnet}/100.100.100.100"
          ];
        };
      };

      services.pihole-web = {
        enable = true;
        ports = [ 80 ];
      };

      # Reachable over the tailnet only, not the LAN/WAN-facing interface.
      networking.firewall.interfaces."tailscale0" = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [
          53
          80 # web UI
        ];
      };
    };
}
