{ ren, lib, ... }:
let
  serviceDomains = [ "forgejo" ];
in
{
  ren.aspects.svc-web-forgejo = {
    includes = with ren.aspects; [ svc-networking-nginx ];

    nixos =
      {
        config,
        environment,
        host,
        ...
      }:
      let
        domain = ren.helpers.domainFor environment "forgejo";
      in
      {
        users.groups.git = { };
        users.users.git = {
          isSystemUser = true;
          useDefaultShell = true;
          group = "git";
          home = config.services.forgejo.stateDir;
        };

        services.openssh = {
          authorizedKeysFiles = lib.mkForce [
            "${config.services.forgejo.stateDir}/.ssh/authorized_keys"
          ];
          settings.AcceptEnv = [ "GIT_PROTOCOL" ];
        };

        services.nginx.virtualHosts."${domain}" = {
          forceSSL = true;
          useACMEHost = environment.domain;
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true;
          };
        };
      };

    firewall = {
      networking.firewall.allowedTCPPorts = [ 7654 ];
    };

    service-domains = serviceDomains;
    served-domains = { environment, host, ... }: ren.helpers.servedDomains environment host serviceDomains;

    persist = {
      directories = [
        {
          directory = "/var/lib/forgejo";
          user = "git";
          group = "git";
          mode = "0700";
        }
      ];
    };
  };
}
