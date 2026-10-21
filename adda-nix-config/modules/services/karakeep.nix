# services: karakeep
{ ren, ... }:
{
  ren.aspects.services-karakeep.nixos =
    { fleet, ... }:
    let
      serviceName = "karakeep";
      hostName = "${serviceName}.${fleet.tailnet}";
    in
    {
      services.karakeep = {
        enable = true;
        extraEnvironment = {
          # DISABLE_SIGNUPS = "true"; # Cannot create even the first admin user, however.
          DISABLE_NEW_RELEASE_CHECK = "true";
          NEXTAUTH_URL = "https://${hostName}";
        };
      };
    };

  ren.aspects.services-karakeep.service-domains = { ... }: _: {
    subdomain = "karakeep";
    extraConfig = ''
      reverse_proxy localhost:3000
    '';
  };
}
