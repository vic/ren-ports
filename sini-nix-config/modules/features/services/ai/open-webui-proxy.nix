# Open WebUI: nginx vhost, service user, OIDC secrets, served domain, state (see open-webui.nix).
{ ren, ... }:
{
  ren.aspects.svc-ai-open-webui = {
    nixos =
      { environment, config, ... }:
      let
        domain = ren.helpers.domainFor environment "open-webui";
      in
      {
        services.nginx.virtualHosts."${domain}" = {
          forceSSL = true;
          useACMEHost = environment.domain;
          locations."/" = {
            proxyPass = "http://127.0.0.1:10715";
            proxyWebsockets = true;
            extraConfig = ''
              client_max_body_size 256m;
              proxy_buffering off;
            '';
          };
        };

        users.groups.open-webui = { };
        users.users.open-webui = {
          group = "open-webui";
          isSystemUser = true;
        };

        systemd.services.open-webui.serviceConfig = {
          User = "open-webui";
          Group = "open-webui";
        };

        # Set directly in nixos: the body reads class `config` (generator.dependencies).
        age.secrets = {
          open-webui-oidc-secret = {
            rekeyFile = environment.secretPath + "/oidc/open-webui-oidc-client-secret.age";
            generator = {
              tags = [ "oidc" ];
              script = "rfc3986-secret";
            };
            intermediary = true;
          };

          open-webui-env = {
            generator.dependencies = [ config.age.secrets.open-webui-oidc-secret ];
            settings.keys = [ "OAUTH_CLIENT_SECRET" ];
            generator.script = "environment-file";
          };
        };
      };

    service-domains = [ "open-webui" ];
    served-domains = { environment, host, ... }: ren.helpers.servedDomains environment host [ "open-webui" ];

    persist.directories = [
      {
        directory = "/var/lib/private/open-webui";
        user = "open-webui";
        group = "open-webui";
        mode = "0700";
      }
    ];
  };
}
