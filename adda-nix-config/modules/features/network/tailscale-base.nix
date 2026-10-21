# Tailscale + firewall + resolver baseline of every host; the tailnet and DNS come from the fleet.
{ ren, ... }:
{
  # `--operator` names the account tailscaled chowns /run/tailscale/tailscaled.sock
  #  to, so `tailscale up/set/status` need no sudo. It is a property of a *user*, not
  #  of the host, hence a user aspect with `os` content: once per user on its host.
  # Both flag lists get it: extraUpFlags only applies on the first/reauth `up`,
  #  extraSetFlags is what tailscaled-set.service reasserts on every boot.
  ren.aspects.tailscale-operator = {
    at = ren.kinds.user;
    os =
      { user, ... }:
      {
        services.tailscale = {
          extraUpFlags = [ "--operator=${user.name}" ];
          extraSetFlags = [ "--operator=${user.name}" ];
        };
      };
  };

  ren.aspects.tailscale-base.at = ren.kinds.host;
  ren.aspects.tailscale-base.nixos =
    {
      fleet,
      lib,
      pkgs,
      ...
    }:
    {
      # environment.systemPackages = with pkgs; [
      #   # opensnitch
      #   # opensnitch-ui
      # ];

      # services.opensnitch-ui.enable = true;

      #services.opensnitch = {
      #  enable = true;
      #  settings = builtins.fromJSON (builtins.readFile ../../home-manager/dotfiles/etc/opensnitchd/default-config.json);
      #};

      networking = {
        firewall = {
          enable = true;

          # Open ports in the firewall.
          allowedTCPPorts = [
            80
            443
          ];
          #allowedUDPPortRanges = [
          # { from = 4000; to = 4007; }
          # { from = 8000; to = 8010; }
          #];
        };
      };

      services.resolved.enable = true;

      services.tailscale = {
        enable = true;
        permitCertUid = "caddy";
        useRoutingFeatures = "both";
        extraUpFlags = [ "--ssh" ];
        extraSetFlags = [ "--ssh" ];
        # Use for containers where one cannot create tunnel networking TUN.
        # interfaceName = "userspace-networking";
      };

      networking = {
        # This host's own stub resolver — unrelated to the resolvers' bootstrap/upstream
        #  lists, this is only what local programs (nix, curl, systemd units) ask.
        # Exactly three tiers, because glibc reads at most MAXNS = 3 entries from
        #  resolv.conf and tries them in order; a fourth would be unreachable on
        #  mensa-nixos, where the resolver aspect forces resolved off and openresolv writes
        #  the file. On workstations resolved consumes the same three via Resolve.DNS=.
        # Every tier filters something, so no outage can silently downgrade this host to
        #  unfiltered DNS. All three are plaintext :53 — a fallback that must work before
        #  the local resolver does cannot be encrypted.
        nameservers = [
          # 1. MagicDNS: the only server that answers tailnet names, and the tailnet-wide
          #    nameserver behind it (terraform/tailscale/dns.tf) is mensa-nixos, so queries
          #    land in the self-hosted, blocklist-filtered, DoQ-fronted resolver.
          "100.100.100.100"
          # 2. Quad9 direct, taken from the same list the resolvers bootstrap against, so
          #    changing provider there changes it here too. Blocks malware domains.
          (lib.head fleet.plainDns)
          # 3. Last resort when both the tailnet and Quad9 are unreachable. 1.1.1.2, not
          #    1.1.1.1: the .2 address is Cloudflare's malware-blocking variant (.3 also
          #    blocks adult content). Malware only — no ad/tracker filtering down here.
          "1.1.1.2"
        ];
        search = [ fleet.tailnet ];
      };

      services.networkd-dispatcher = {
        enable = true;
        rules."50-tailscale" = {
          onState = [ "routable" ];
          script = /* sh */ ''
            # $IFACE is set by networkd-dispatcher to whichever interface just became routable.
            # Skip loopback/tailscale0: the GRO tweak is for the physical WAN-facing NIC (ethernet dock or WiFi),
            #  whose name isn't stable (e.g. the USB dock enumerates as enp102s0f3u1u1, enp102s0f3u1u2, ... depending
            #  on the port used).
            if [ "$IFACE" != "lo" ] && [ "$IFACE" != "tailscale0" ]; then
              ${lib.getExe pkgs.ethtool} -K "$IFACE" rx-udp-gro-forwarding on rx-gro-list off || true
            fi
          '';
        };
      };

      systemd.timers = {
        tailscale-cert-renewal-timer = {
          description = "Timer for renewal of tailscale cert";
          partOf = [ "tailscale-cert-renewal.service" ];
          wantedBy = [ "timers.target" ];
          timerConfig = {
            # Run weekly because Let's Encrypt might decide not to renew when the certificate expiry is too far off.
            # So we just run this again until hopefully we get to renew the cert.
            OnCalendar = "Mon *-*-* 16:37:00";
            # Launch the service even if the system was turned off last time the timer triggered
            Persistent = true;
            Unit = "tailscale-cert-renewal.service";
          };
        };
      };
    };
}
