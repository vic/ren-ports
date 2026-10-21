# services: caddy reverse proxy over the tailnet, fronting every `service-domains` emission
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  # Services emit `service-domains` (a fn of the realized NixOS config) on their host; caddy fronts them all.
  ren.channels.service-domains = {
    fold = ren.lib.fold.list;
    at = ren.kinds.host;
    to = e: e;
  };

  ren.aspects.services-caddy.nixos =
    {
      config,
      fleet,
      lib,
      pkgs,
      service-domains,
      ...
    }:
    let
      serviceDomains = map (f: f config) service-domains;
    in
    {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [
            # Extract version from
            #  https://api.github.com/repos/tailscale/caddy-tailscale/commits/main
            #  as commmiter date, e.g. "2025-02-07T16:39:03Z" -> "20250207163903",
            #  SHA hash of the commit, e.g. "bb080c4414acb9e5a1c8e7f0d9b2a1c3d4e5f6",
            #  and combine them into "v0.0.0-20250207163903-bb080c4414ac" to get the version string for the plugin.
            "github.com/tailscale/caddy-tailscale@v0.0.0-20260826180304-de41b249af4f"
          ];
          hash = "sha256-OzzyBF/SA1WkX/g+WOwvZo2t5bfeNPOeYJ1ziOLlTTk=";
        };
        enableReload = false; # I think caddy-tailscale breaks this
        globalConfig = ''
          # servers {
          #   metrics
          # }
          tailscale {
            ephemeral true
            ${lib.concatMapStrings (
              domain:
              lib.optionalString (domain ? tailscaleAuthKeyEnv) ''
                # A node enrolled with its own key carries that key's tags instead of the shared TS_AUTHKEY's.
                ${domain.subdomain} {
                  auth_key {env.${domain.tailscaleAuthKeyEnv}}
                }
              ''
            ) serviceDomains}
          }
        '';
        logFormat = ''
          output file /var/log/caddy/caddy_main.log {
            roll_size 100MiB
            roll_keep 5
            roll_keep_for 100d
          }
          format json
          level INFO
        '';
        # extraConfig = ''
        #   (blackholeCrawlers) {
        #     defender drop {
        #       ranges vpn aws deepseek githubcopilot gcloud azurepubliccloud openai mistral vultr digitalocean linode
        #     }
        #   }
        # '';

        virtualHosts = lib.listToAttrs (
          map (domain: {
            name = "https://${domain.subdomain}.${fleet.tailnet}";
            value.extraConfig = /* caddyfile */ ''
              bind tailscale/${domain.subdomain} # Creates a new node at ${domain.subdomain}.${fleet.tailnet}.
              ${lib.optionalString (domain.tailscaleAuth or true
              ) "tailscale_auth # Enables the in-built authentication provider."}
              ${domain.extraConfig}
            '';
          }) serviceDomains
        );
      };

      # environment.etc."caddy-tailscale-auth-key.env".text =
      #   lib.readFile ./certs/caddy-tailscale-auth-key.key;
      # services.caddy.environmentFile = "/etc/caddy-tailscale-auth-key.env";
      sops.secrets.services-tailscale-tsauthkey = {
        sopsFile = addax.secretsPath "services-tailscale-tsauthkey.env";
        # owner = config.services.caddy.user;
        format = "dotenv";
      };
      services.caddy.environmentFile = config.sops.secrets.services-tailscale-tsauthkey.path;

      # age.secrets.ts-authkey = {
      #   file = "secrets/ts-authkey.age";
      #   owner = config.services.caddy.user;
      #   group = config.services.caddy.group;
      #   mode = "600";
      # };
      # systemd.services.caddy.serviceConfig.EnvironmentFile = config.age.secrets.ts-authkey.path;
    };
}
