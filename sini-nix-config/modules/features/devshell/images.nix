# devshell: OCI/Helm image update commands.
{ ren, inputs, ... }:
{
  ren.aspects.devshell-images = {
    at = ren.system.x86_64-linux;
    devshell =
      { system, ... }:
      {
        commands = [
          {
            name = "helmupdater";
            command = ''${inputs.nixhelm.packages.${system.name}.helmupdater}/bin/helmupdater "$@"'';
            help = "Update helm chart versions and hashes";
          }
          {
            package = inputs.self.packages.${system.name}.oci-image-updater;
            name = "oci-image-updater";
            help = "Update OCI container image versions and hashes";
          }
        ];
      };
  };
}
