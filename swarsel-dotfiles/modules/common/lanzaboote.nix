{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.lanzaboote.flake-inputs.lanzaboote = {
    inputs = {
      nixpkgs.follows = "nixpkgs";
      pre-commit.follows = "pre-commit-hooks";
    };
    url = "github:nix-community/lanzaboote";
  };

  ren.aspects.lanzaboote.nixos =
    {
      variant,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.swarselsystems) isImpermanence isSecureBoot;
    in
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];
      boot = {
        lanzaboote = lib.mkIf (!variant.minimal && isSecureBoot) {
          enable = true;
          configurationLimit = 6;
          pkiBundle = "/var/lib/sbctl";
        };
        loader = {
          efi.canTouchEfiVariables = true;
          systemd-boot.enable = sw.mkIfElse (variant.minimal || !isSecureBoot) (lib.mkForce true) (
            lib.mkForce false
          );
        };
      };
      environment = {
        persistence."/persist" = lib.mkIf (isImpermanence && isSecureBoot) {
          directories = [ { directory = "/var/lib/sbctl"; } ];
        };
        systemPackages = lib.mkIf isSecureBoot [
          pkgs.sbctl
        ];
      };
    };
}
