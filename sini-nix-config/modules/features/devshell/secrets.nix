# devshell: secrets commands.
{ ren, inputs, ... }:
{
  ren.aspects.devshell-secrets = {
    at = ren.system.x86_64-linux;
    devshell =
      { system, ... }:
      {
        commands = [
          {
            package = inputs.self.packages.${system.name}.generate-vault-certs;
            name = "generate-vault-certs";
            help = "Generate certificates for Vault raft cluster";
          }
          {
            package = inputs.self.packages.${system.name}.generate-user-keys;
            name = "generate-user-keys";
            help = "Generate and encrypt ed25519 SSH keys for users";
          }
        ];
      };
  };
}
