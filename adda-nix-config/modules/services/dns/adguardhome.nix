# services: adguardhome DNS resolver
{ ren, inputs, ... }:
{
  ren.aspects.services-dns-adguardhome.nixos =
    {
      fleet,
      lib,
      ...
    }:
    {
      # resolved's stub listener (127.0.0.53:53) blocks AdGuard Home's own :53 bind
      #  (TCP wildcard binds conflict with an existing specific-address listener).
      services.resolved.enable = lib.mkForce false;

      services.adguardhome = {
        enable = true;
        settings = {
          users = [ ];
          dns = {
            bootstrap_dns = fleet.plainDns;
            upstream_dns = fleet.upstreamDns ++ [
              "[/${fleet.tailnet}/]100.100.100.100"
            ];
          };

          filters = [
            {
              enabled = true;
              name = "AdGuard DNS filter";
              url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
              id = 1;
            }
            {
              enabled = true;
              name = "OISD Big";
              url = "https://big.oisd.nl/";
              id = 2;
            }
            {
              enabled = true;
              name = "Steven Black's unified hosts";
              url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
              id = 3;
            }
            {
              enabled = true;
              name = "AdGuard Tracking Protection filter";
              url = "https://filters.adtidy.org/extension/chromium/filters/3.txt";
              id = 4;
            }
            {
              enabled = true;
              name = "EasyPrivacy";
              url = "https://easylist.to/easylist/easyprivacy.txt";
              id = 5;
            }
          ];
        };
      };

      networking.firewall.interfaces."tailscale0" = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 53 ];
      };
    };

  ren.aspects.services-dns-adguardhome.service-domains = { ... }: config: {
    subdomain = "adguard";
    extraConfig = /* caddyfile */ ''
      reverse_proxy localhost:${inputs.nixpkgs.lib.last (inputs.nixpkgs.lib.splitString ":" config.services.adguardhome.settings.http.address)}
    '';
  };
}
