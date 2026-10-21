# services: freshrss
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.services-freshrss.nixos =
    {
      config,
      fleet,
      pkgs,
      ...
    }:
    let
      hostName = "freshrss.${fleet.tailnet}";
      hostUrl = "https://${hostName}";
    in
    {
      services.freshrss = {
        enable = true;
        # baseUrl = "${hostName}:${toString port}";
        baseUrl = hostUrl;
        virtualHost = hostName;
        authType = "http_auth";
        # database.host = hostName;
        # database.port = 3306;
        passwordFile = config.sops.secrets.freshrssPassword.path;
        webserver = "caddy";
        api.enable = true;
        extensions = with pkgs.freshrss-extensions; [
          youtube
          reading-time
          title-wrap
        ]
        # ++ [
        #   (freshrss-extensions.buildFreshRssExtension {
        #     FreshRssExtUniqueId = "ReadingTime";
        #     pname = "reading-time";
        #     version = "1.5";
        #     src = pkgs.fetchFromGitLab {
        #       domain = "framagit.org";
        #       owner = "Lapineige";
        #       repo = "FreshRSS_Extension-ReadingTime";
        #       rev = "fb6e9e944ef6c5299fa56ffddbe04c41e5a34ebf";
        #       hash = "sha256-C5cRfaphx4Qz2xg2z+v5qRji8WVSIpvzMbethTdSqsk=";
        #     };
        #   })
        # ]
        ;
      };
      sops.secrets = {
        freshrssPassword = {
          sopsFile = addax.secretsPath "freshrss.yaml";
          format = "yaml";
          key = "password";
        };
        freshrssDatabasePassword = {
          sopsFile = addax.secretsPath "freshrss.yaml";
          format = "yaml";
          key = "password";
        };
      };

    };

  ren.aspects.services-freshrss.service-domains = { ... }: config: {
    subdomain = "freshrss";
    extraConfig = /* caddyfile */ ''
      root * ${config.services.freshrss.package}/p
      php_fastcgi unix/${config.services.phpfpm.pools.freshrss.socket} {
        env FRESHRSS_DATA_PATH ${config.services.freshrss.dataDir}
      }
      file_server
      # reverse_proxy localhost:$ {toString config.services.freshrss.port} {
      #   header_up X-Webauth-User {http.auth.user.tailscale_user}
      # }
      # reverse_proxy localhost:${toString config.services.freshrss.database.port} {
      #   header_up X-Webauth-User {http.auth.user.tailscale_user}
      # }
      # header_up X-Webauth-User {http.auth.user.tailscale_user}
    '';
  };
}
