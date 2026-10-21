# The unifi workspace's state passphrase, declared like dns-state-passphrase.
{ ren, ... }:
{
  ren.aspects.unifi-state-passphrase-age-secrets = {
    # no `at`: as sini, only uplink includes it (secret lands on uplink nixos)
    age-secrets =
      { environment, ... }:
      {
        age.secrets.unifi-state-passphrase = {
          rekeyFile = environment.secretPath + "/unifi-state-passphrase.age";
          intermediary = true;
          generator.script = "rfc3986-secret";
        };
      };
  };
}
