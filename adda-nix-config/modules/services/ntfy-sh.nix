# services: ntfy-sh
{ ren, ... }:
let
  serviceName = "ntfy";
in
{
  ren.aspects.services-ntfy-sh.nixos =
    { fleet, ... }:
    let
      hostName = "${serviceName}.${fleet.tailnet}";
    in
    {
      services.ntfy-sh = {
        enable = true;
        settings = {
          # Baked into attachment/e-mail links and used by the web app to build the topic URLs it subscribes to.
          base-url = "https://${hostName}";

          # Caddy is the only peer ntfy ever sees. Without this, every publisher shares caddy's 127.0.0.1 visitor
          #  identity and they all contend for a single visitor's rate-limit bucket. With it, ntfy takes the real client
          #  from the X-Forwarded-For caddy sets.
          behind-proxy = true;
        };
      };
    };

  ren.aspects.services-ntfy-sh.service-domains = { ... }: config: {
    subdomain = serviceName;
    extraConfig = /* caddyfile */ ''
      reverse_proxy ${config.services.ntfy-sh.settings.listen-http}
    '';
  };
}
