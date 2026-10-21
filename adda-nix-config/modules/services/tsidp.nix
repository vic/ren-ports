# services: tsidp
{ ren, ... }:
{
  # OIDC IdP backed by the tailnet's own identities; mensa-nixos' LiteLLM admin UI logs in
  #  through it. Runs as its own tsnet node `idp.<tailnet>` (Tailnet MagicDNS + HTTPS), so
  #  there is no caddy vhost for it — caddy's tailscale_auth is irrelevant to it, and the
  #  enrolment is authorized by the ACL alone.
  ren.aspects.services-tsidp.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      systemd.services.tsidp = {
        description = "Tailscale OIDC Identity Provider";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        environment.TAILSCALE_USE_WIP_CODE = "1";
        # TS_AUTHKEY comes from the shared services env file (tag:homelab-caddy).
        serviceConfig = {
          ExecStart = lib.concatStringsSep " " [
            "${lib.getExe pkgs.tsidp}"
            "-dir /var/lib/tsidp"
            "-hostname idp"
          ];
          EnvironmentFile = config.sops.secrets.services-tailscale-tsauthkey.path;
          StateDirectory = "tsidp";
          # tsnet registers its own node over userspace networking, so no port binding or
          #  privileges are needed; keep the rest of the sandbox tight anyway.
          DynamicUser = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };
    };

  # No serviceDomains entry: tsidp enrols its own tailnet node, it is not fronted by caddy.
}
