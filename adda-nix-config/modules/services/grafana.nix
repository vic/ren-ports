# services: grafana
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.services-grafana.nixos =
    { config, fleet, ... }:
    let
      serviceName = "grafana";
      serviceDomain = "${serviceName}.${fleet.tailnet}";
      address = "localhost";
      # address = "127.0.0.1";
      port = 2342;
    in
    {
      services.grafana = {
        enable = false;
        settings = {
          "auth.proxy" = {
            enabled = true; # Enable proxy-based authentication.
            auto_sign_up = true; # Automatically create new accounts for people who access the service.
            enable_login_token = false; # Do not store login cookies, instead always relying on proxy authentication.
            security.secret_key = "$__file{${config.sops.secrets.grafana.path}}"; # FIXME: Does not work, Nix does not seem to be able to read the secret value at this point...
            # security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
          };
          server = {
            domain = serviceDomain;
            http_addr = address;
            http_port = port;
          };
        };
      };

      sops.secrets.grafana = {
        sopsFile = addax.secretsPath "grafana.ini";
        # owner = config.services.grafana.user;
        # key = "security.secret_key";
        format = "ini";
      };
    };

  ren.aspects.services-grafana.service-domains = { ... }: config: {
    subdomain = "grafana";
    extraConfig = /* caddyfile */ ''
      reverse_proxy ${config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port} {
        header_up X-Webauth-User {http.auth.user.tailscale_user}
      }
    '';
  };
}
