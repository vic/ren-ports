{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.nswitch-rcm.flake-inputs.nswitch-rcm-nix = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:Swarsel/nswitch-rcm-nix";
  };

  ren.aspects.nswitch-rcm.nixos =
    {
      lib,
      ...
    }:
    {
    imports = lib.optionals (inputs ? nswitch-rcm-nix) [
      inputs.nswitch-rcm-nix.nixosModules.nswitch-rcm
      ({ pkgs, ... }: {
        services.nswitch-rcm = {
          enable = true;
          package = pkgs.fetchurl {
            hash = "sha256-5AXzNsny45SPLIrvWJA9/JlOCal5l6Y++Cm+RtlJppI=";
            url = "https://github.com/Atmosphere-NX/Atmosphere/releases/download/1.3.2/fusee.bin";
          };
        };
      })
    ];
  };
}
