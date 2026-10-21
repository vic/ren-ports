{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.sops.flake-inputs.sops = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Mic92/sops-nix";
  };

  ren.aspects = {
    sops.homeManager =
      {
        osConfig ? null,
        config,
        lib,
        ...
      }:
      {
        imports = [ inputs.sops.homeManagerModules.sops ];
        swarselsystems.enabledHomeModules = [ "sops" ];
        sops = lib.mkIf (osConfig == null) {
          age.sshKeyPaths = [
            "${
              if config.swarselsystems.isImpermanence then "/persist" else ""
            }${config.swarselsystems.homeDir}/.ssh/sops"
          ];
          defaultSopsFile = inputs.self + "/secrets/repo/common.yaml";
          secrets = lib.mkIf (!config.swarselsystems.isPublic) config.swarselsystems.homeSopsSecrets;
          templates = lib.mkIf (!config.swarselsystems.isPublic) config.swarselsystems.homeSopsTemplates;
          validateSopsFiles = false;
        };
      };
    sops.nixos =
      {
        config,
        ...
      }:
      {
        imports = [ inputs.sops.nixosModules.sops ];

        sops = {
          age.sshKeyPaths = [
            "${if config.swarselsystems.isImpermanence then "/persist" else ""}/etc/ssh/ssh_host_ed25519_key"
          ];
          defaultSopsFile = inputs.self + "/secrets/repo/common.yaml";
          validateSopsFiles = false;
        };
      };
  };
}
