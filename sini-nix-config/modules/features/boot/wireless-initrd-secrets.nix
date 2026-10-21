# Wireless initrd secrets: wpa_supplicant config generator + first-boot activation.
{ ... }:
{
  ren.aspects.boot-wireless-initrd = {
    nixos =
      { config, ... }:
      let
        inherit (config.age) secrets;
      in
      {
        # Wire generator dependency for wpa-supplicant-initrd (needs NixOS config context)
        age.secrets.wpa-supplicant-initrd.generator.dependencies = [
          config.age.secrets.wpa-supplicant-keys-for-initrd
        ];

        system.activationScripts = {
          agenixEnsureInitrdWpaSupplicantConfig = {
            text = ''
              if [[ ! -e ${secrets.wpa-supplicant-initrd.path} ]]; then
                cat > ${secrets.wpa-supplicant-initrd.path} <<'EOF'
              ctrl_interface=/var/run/wpa_supplicant
              update_config=1
              EOF
                chmod 600 ${secrets.wpa-supplicant-initrd.path}
              fi
            '';
            deps = [
              "agenixInstall"
            ];
          };

          agenixChown.deps = [
            "agenixEnsureInitrdWpaSupplicantConfig"
          ];
        };
      };

    age-secrets =
      { environment, ... }:
      let
        inherit ((environment.networks.default or { })) wireless;
      in
      {
        age.secrets = {
          wpa-supplicant-keys-for-initrd = {
            intermediary = true;
            rekeyFile = environment.wirelessSecretsFile;
          };

          wpa-supplicant-initrd = {
            generator.script = "wpa-supplicant-config";
            settings.networks =
              if wireless != null then { "${wireless.ssid}".pskRaw = wireless.pskRef; } else { };
          };
        };
      };
  };
}
