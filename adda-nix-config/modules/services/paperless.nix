# services: paperless
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.services-paperless.nixos =
    { config, ... }:
    {
      nixpkgs.overlays = [
        (_final: prev: {
          paperless-ngx = prev.paperless-ngx.overrideAttrs {
            doCheck = false;
            doInstallCheck = false;
          };
        })
      ];

      services.paperless = {
        enable = true;
        settings = {
          PAPERLESS_CONSUMER_IGNORE_PATTERN = [
            ".DS_STORE/*"
            "desktop.ini"
          ];
          PAPERLESS_OCR_LANGUAGE = "eng+ces";
          PAPERLESS_OCR_USER_ARGS = {
            optimize = 1;
            pdfa_image_compression = "lossless";
          };
          # Use only on secure local network, not suitable for open internet.
          PAPERLESS_AUTO_LOGIN_USERNAME = "admin";
          # PAPERLESS_ADMIN_PASSWORD = "01234567890";
        };
        passwordFile = config.sops.secrets.paperlessAdminPass.path;

        database.createLocally = true;
      };
      # environment.etc."paperless-admin-pass".text = "01234567890";

      sops.secrets.paperlessAdminPass = {
        sopsFile = addax.secretsPath "paperless.yaml";
        # owner = config.services.paperless.user;
        key = "admin_password";
        format = "yaml";
      };
    };

  ren.aspects.services-paperless.service-domains = { ... }: config: {
    subdomain = "paperless";
    extraConfig = ''
      reverse_proxy localhost:${toString config.services.paperless.port} {
        header_up X-Webauth-User {http.auth.user.tailscale_user}
      }
    '';
  };
}
