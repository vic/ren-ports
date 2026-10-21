# Tailscale auth key, generated against the headscale host; shared by the Linux
# and Darwin concerns of the tailscale aspect (den: class-less fn aspect = `os`).
{ ren, ... }:
{
  ren.aspects.network-tailscale-age-secrets.os =
    { environment, host, ... }:
    {
      age.secrets.tailscale-auth-key = {
        rekeyFile = host.secretPath + "/tailscale-preauthkey.age";
        settings = {
          headscaleHost = ren.helpers.domainFor environment "headscale";
          user = host.name;
        };
        generator.script = "tailscale-preauthkey";
      };
    };
}
