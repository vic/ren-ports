{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.stylix.flake-inputs.stylix = {
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
      nur.follows = "nur";
      systems.follows = "systems";
    };
    url = "github:danth/stylix";
  };

  ren.aspects = {
    stylix.homeManager =
      {
        globals-defs,
        machine,
        lib,
        ...
      }:
      {
        imports = lib.optionals (inputs ? stylix) (
          lib.optionals ((sw.typeOf machine) != "nixos") [ inputs.stylix.homeModules.stylix ]
          ++ [
            (
              {
                pkgs,
                config,
                lib,
                osConfig ? null,
                ...
              }:
              let
                vars = sw.varsOf {
                  inherit config lib pkgs;
                  globals = sw.globalsOf globals-defs;
                };
              in
              {
                swarselsystems.enabledHomeModules = [ "stylix" ];
                gtk.gtk4.theme = lib.mkForce config.gtk.theme;
                home.pointerCursor.enable = lib.mkIf (config.stylix.enable && config.stylix.cursor != null) true;
                stylix = {
                  targets = vars.stylixHomeTargets // {
                    spicetify.enable = if (machine.system.name == "aarch64-linux") then false else true;
                  };
                }
                // lib.optionalAttrs (osConfig == null) (
                  lib.recursiveUpdate {
                    enable = true;
                    base16Scheme = sw.root "files/stylix/swarsel.yaml";
                  } vars.stylix
                );
              }
            )
          ]
        );
      };
    stylix.nixos =
      {
        globals-defs,
        lib,
        ...
      }:
      {
      imports = lib.optionals (inputs ? stylix) [
        inputs.stylix.nixosModules.stylix
        (
          {
            pkgs,
            config,
            lib,
            ...
          }:
          let
            vars = sw.varsOf {
              inherit config lib pkgs;
              globals = sw.globalsOf globals-defs;
            };
          in
          {
            stylix = lib.recursiveUpdate {
              enable = true;
              base16Scheme = sw.root "files/stylix/swarsel.yaml";
              image = config.swarselsystems.wallpaper;
              targets.grub.enable = false; # the styling makes grub more ugly
            } vars.stylix;
          }
        )
      ];
    };
  };
}
