# agenix battery, flake side: flake-file inputs + agenix-rekey devshell tooling.
{ ren, inputs, ... }:
let
  rekey = inputs.agenix-rekey.configure {
    userFlake = inputs.self;
    inherit (inputs.self) nixosConfigurations;
  };
in
{
  ren.aspects.secrets-agenix-inputs = {
    at = ren.kinds.fleet;
    flake-inputs = {
      agenix = {
        url = "github:ryantm/agenix";
        inputs.home-manager.follows = "home-manager";
        inputs.nixpkgs.follows = "nixpkgs-unstable";
      };
      agenix-rekey = {
        url = "github:sini/agenix-rekey/feat/settings";
        inputs.nixpkgs.follows = "nixpkgs-unstable";
      };
      agenix-rekey-to-sops = {
        url = "github:sini/agenix-rekey-to-sops";
        inputs.nixpkgs.follows = "nixpkgs-unstable";
        inputs.agenix-rekey.follows = "agenix-rekey";
      };
    };
  };
  ren.aspects.secrets-agenix-rekey = {
    at = ren.kinds.system;
    devshell =
      { pkgs, system, ... }:
      {
        packages = [ pkgs.age pkgs.age-plugin-yubikey ];
        env = [
          { name = "AGENIX_REKEY_ADD_TO_GIT"; value = "true"; }
          { name = "SOPS_AGE_KEY_CMD"; value = "age-plugin-yubikey -i"; }
        ];
        commands = [
          {
            package = inputs.agenix-rekey.packages.${system.name}.default;
            help = "agenix rekey / generate / edit";
          }
        ];
      };
    apps = { system, ... }: rekey.${system.name};
  };
}
