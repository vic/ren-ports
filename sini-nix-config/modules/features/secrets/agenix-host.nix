# agenix battery, host side: agenix + agenix-rekey modules per class, age.rekey from fleet secretsConfig.
# droid has no system agenix module, so nixos/darwin only (aspect skips droid).
{ ren, lib, inputs, ... }:
let
  inherit (ren.lib) and not;
  # darwin impermanence is a dummy (no /persist); only nixos relocates the host key
  rekey =
    machine: fleet: persistPrefix:
    { config, ... }:
    {
      age = {
        # agenix decrypts before impermanence creates mounts
        identityPaths = [ "${persistPrefix}/etc/ssh/ssh_host_ed25519_key" ];
        rekey = {
          inherit (fleet.secretsConfig) masterIdentities;
          storageMode = "local";
          hostPubkey = builtins.readFile machine.public_key;
          generatedSecretsDir = machine.secretPath + "/generated";
          localStorageDir = machine.secretPath + "/rekeyed";
        };
      };
    };
in
{
  ren.aspects.secrets-agenix-host = {
    at = and [ ren.kinds.machine (not ren.kinds.droid) ];
    nixos =
      { is, host, fleet, config, ... }:
      {
        imports = [
          inputs.agenix.nixosModules.default
          inputs.agenix-rekey.nixosModules.default
          ../secrets/_generators-module.nix
          (rekey host fleet (if is ren.aspects.impermanence host then "/persist" else ""))
        ];
        # remove agenix directory before switching if it is a dir instead of a link
        system.activationScripts = lib.mkIf (config.age.secrets != { }) {
          removeAgenixLink.text = "[[ ! -L /run/agenix ]] && [[ -d /run/agenix ]] && rm -rf /run/agenix";
          agenixNewGeneration.deps = [ "removeAgenixLink" ];
        };
      };
    darwin =
      { mac, fleet, ... }:
      {
        imports = [
          inputs.agenix.darwinModules.default
          inputs.agenix-rekey.darwinModules.default
          ../secrets/_generators-module.nix
          (rekey mac fleet "")
        ];
      };
  };
}
