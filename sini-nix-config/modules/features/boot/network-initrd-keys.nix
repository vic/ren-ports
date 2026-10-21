# Initrd host key: persisted, generated, and ensured to exist on first boot.
{ ... }:
{
  ren.aspects.boot-network-initrd = {
    nixos =
      { config, pkgs, ... }:
      let
        inherit (config.age) secrets;
      in
      {
        # Ensure valid initrd host key exists even on first boot
        system.activationScripts = {
          agenixEnsureInitrdHostkey = {
            text = ''
              [[ -e ${secrets.initrd_host_ed25519_key.path} ]] \
                || ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f ${secrets.initrd_host_ed25519_key.path}
            '';
            deps = [
              "agenixInstall"
              "users"
            ];
          };

          agenixChown.deps = [
            "agenixEnsureInitrdHostkey"
          ];
        };
      };

    persist = {
      files = [
        "/etc/ssh/initrd_host_ed25519_key"
        "/etc/ssh/initrd_host_ed25519_key.pub"
      ];
    };

    age-secrets = {
      age.secrets.initrd_host_ed25519_key.generator.script = "ssh-key";
    };
  };
}
