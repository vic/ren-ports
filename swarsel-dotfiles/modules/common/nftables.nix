{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.nftables.flake-inputs.nixos-nftables-firewall.url = "github:thelegy/nixos-nftables-firewall";

  ren.aspects = {
    nftables.nixos =
      {
        ...
      }:
      {
        imports = [ inputs.nixos-nftables-firewall.nixosModules.default ];
      };

    nftables-rules.nixos =
      {
        config,
        lib,
        ...
      }:
      {
        config = {
          swarselsystems.enabledServerModules = [ "nftables" ];
          networking.nftables = {
            firewall = {
              enable = true;
              localZoneName = "local";
              rules = {
                icmp-and-igmp = {
                  after = [
                    "ct"
                    "ssh"
                  ];
                  extraLines = [
                    "meta l4proto ipv6-icmp accept"
                    "meta l4proto icmp accept"
                    "ip protocol igmp accept"
                  ];
                  from = "all";
                  to = [ "local" ];
                };
                untrusted-to-local = {
                  inherit (config.networking.firewall)
                    allowedTCPPortRanges
                    allowedTCPPorts
                    allowedUDPPortRanges
                    allowedUDPPorts
                    ;
                  from = [ "untrusted" ];
                  to = [ "local" ];
                };
              };
              snippets = {
                nnf-common.enable = false;
                nnf-conntrack.enable = true;
                nnf-dhcpv6.enable = true;
                nnf-drop.enable = true;
                nnf-loopback.enable = true;
                nnf-ssh.enable = true;
              };
            };
            stopRuleset = lib.mkDefault ''
              table inet filter {
                chain input {
                  type filter hook input priority filter; policy drop;
                  ct state invalid drop
                  ct state {established, related} accept

                  iifname lo accept
                  meta l4proto ipv6-icmp accept
                  meta l4proto icmp accept
                  ip protocol igmp accept
                  tcp dport ${toString (lib.head config.services.openssh.ports)} accept
                }
                chain forward {
                  type filter hook forward priority filter; policy drop;
                }
                chain output {
                  type filter hook output priority filter; policy accept;
                }
              }
            '';
          };

        };
        key = "swarsel/nftables-rules";
      };
  };
}
