{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.spicetify.flake-inputs.spicetify-nix = {
    inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
    };
    url = "github:Gerg-l/spicetify-nix";
  };

  ren.aspects.spicetify.homeManager =
    {
      machine,
      lib,
      ...
    }:
    {
      imports = lib.optionals (inputs ? spicetify-nix && machine.system.name == "x86_64-linux") [
        inputs.spicetify-nix.homeManagerModules.default
        (
          { inputs, pkgs, ... }:
          let
            spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          in
          {
            swarselsystems.enabledHomeModules = [ "spicetify" ];
            programs.spicetify = {
              enable = true;
              enabledExtensions = with spicePkgs.extensions; [
                fullAppDisplay
                shuffle
                hidePodcasts
                fullAlbumDate
                skipStats
                history
              ];
              # spotifyPackage = pkgs.stable24_11.spotify;
              spotifyPackage = pkgs.spotify;
            };
          }
        )
      ];
    };
}
