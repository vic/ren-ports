# largely based on https://github.com/oddlama/nix-config/blob/main/modules/secrets.nix
{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.pii.generic =
    {
      globals-defs,
      config,
      lib,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      # the loader is shared with the fleet (helpers/pii.nix): it reads the common PII for channels too
      inherit (sw) importEncrypted;
    in
    {
      options.repo = {
        secretFiles = lib.mkOption {
          default = { };
          description = ''
            This file manages the origin for this machine's repository-secrets. Anything that is
            technically not a secret in the classical sense (i.e. that it has to be protected
            after it has been deployed), but something you want to keep secret from the public;
            Anything that you wouldn't want people to see on GitHub, but that can live unencrypted
            on your own devices. Consider it a more ergonomic nix alternative to using git-crypt.

            All of these secrets may (and probably will be) put into the world-readable nix-store
            on the build and target hosts. You'll most likely want to store personally identifiable
            information here, such as:
              - MAC Addreses
              - Static IP addresses
              - Your full name (when configuring your users)
              - Your postal address (when configuring e.g. home-assistant)
              - ...

            Each path given here must be an sops-encrypted .nix file. For each attribute `<name>`,
            the corresponding file will be decrypted, imported and exposed as {option}`repo.secrets.<name>`.
          '';
          example = lib.literalExpression "{ local = ./pii.nix.enc; }";
          type = lib.types.attrsOf lib.types.path;
        };

        secrets = lib.mkOption {
          default = lib.mapAttrs (
            _: x:
            importEncrypted x {
              inherit
                inputs
                config
                lib
                globals
                ;
              inherit (inputs) dns;
              homeLib = lib;
              # old `nodes` (other machines' config) is not available: Ren content never reads realized config
              inherit (inputs.topologyPrivate) topologyPrivate;
            }
          ) config.repo.secretFiles;
          description = "Exposes the loaded repo secrets. This option is read-only.";
          readOnly = true;
          type = lib.types.unspecified;
        };
      };
      config.repo.secretFiles =
        let
          local = config.node.secretsDir + "/pii.nix.enc";
        in
        (lib.optionalAttrs (lib.pathExists local) { inherit local; })
        // {
          common = inputs.repoSecrets.pii;
        };
    };
}
