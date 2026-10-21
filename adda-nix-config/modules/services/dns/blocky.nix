# services: blocky DNS resolver
{ ren, ... }:
{
  ren.aspects.services-dns-blocky.nixos =
    { fleet, lib, ... }:
    {
      # resolved's stub listener (127.0.0.53:53) blocks blocky's own :53 bind
      #  (TCP wildcard binds conflict with an existing specific-address listener).
      services.resolved.enable = lib.mkForce false;

      services.blocky.enable = true;

      services.blocky.settings = {
        ports.dns = 53;

        # Resolves the DoQ/DoH upstream hostnames below. Without it blocky falls back to
        #  the system resolver, which on this host is /etc/resolv.conf — pointing at
        #  blocky itself once it owns :53.
        bootstrapDns = fleet.plainDns;

        upstreams = {
          # "strict" tries upstreams in list order, only moving to the next on failure.
          strategy = "strict";
          groups.default = fleet.upstreamDns;
        };

        # The tailnet domain is carved out to Tailscale's own resolver so tailnet
        #  names keep resolving.
        conditional.mapping.${fleet.tailnet} = "100.100.100.100";

        blocking = {
          denylists = {
            ads = [
              "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"
              "https://big.oisd.nl/"
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            ];
            tracking = [
              "https://filters.adtidy.org/extension/chromium/filters/3.txt"
              "https://easylist.to/easylist/easyprivacy.txt"
            ];
          };
          clientGroupsBlock.default = [
            "ads"
            "tracking"
          ];
        };
      };

      # Reachable over the tailnet only, not the LAN/WAN-facing interface. Unlike the
      #  other three, blocky has no bundled web dashboard — just the DNS port.
      networking.firewall.interfaces."tailscale0".allowedUDPPorts = [ 53 ];
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 53 ];
    };
}
