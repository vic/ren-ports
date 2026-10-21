# devshell: Kubernetes management commands.
{ ren, inputs, ... }:
{
  ren.aspects.devshell-kubernetes = {
    at = ren.system.x86_64-linux;
    devshell =
      { system, ... }:
      {
        commands = [
          {
            package = inputs.self.packages.${system.name}.nixidy-sync;
            name = "nixidy-sync";
            help = "Sync nixidy environment manifests into the repo";
          }
          {
            package = inputs.self.packages.${system.name}.toggle-axon-kubernetes;
            name = "toggle-axon-kubernetes";
            help = "Toggle enable/disable Kubernetes on axon cluster nodes";
          }
          {
            package = inputs.self.packages.${system.name}.convert-oidc-secrets;
            name = "convert-oidc-secrets";
            help = "Convert age-encrypted OIDC secrets to SOPS-encrypted YAML format";
          }
        ];
      };
  };
}
