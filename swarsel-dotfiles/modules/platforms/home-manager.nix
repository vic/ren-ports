# home-manager: one class, four homes (NixOS host, mac, standalone home, nix-on-droid); old mkHalfHost.
{ ren, inputs, ... }:
let
  inherit (ren.lib) and within;
  sw = ren.helpers;
  userIn =
    k:
    and [
      ren.kinds.user
      (within k)
    ];
  # the half hosts carry the identity that NixOS hosts get from the nixos class
  nodeModule = m: type: {
    node = {
      arch = inputs.nixpkgs.lib.mkForce m.system.name;
      name = inputs.nixpkgs.lib.mkForce m.name;
      secretsDir = inputs.self + "/hosts/${type}/${m.system.name}/${m.name}/secrets";
      type = inputs.nixpkgs.lib.mkForce type;
    };
  };
in
{
  ren.classes.homeManager = [
    {
      # old flake/modules.nix export (flake/exports.nix)
      at = userIn ren.kinds.export;
      into = _: ms: { homeModules.imports = ms; };
    }
    {
      at = userIn sw.metal;
      # old nixos.home-manager: no home on servers and MicroVMs
      into =
        { user, ... }:
        ms: {
          nixos = { config, lib, ... }: {
            home-manager = lib.mkIf (!config.swarselsystems.isServer && !config.swarselsystems.isMicroVM) {
              users.${sw.loginOf user}.imports = ms;
            };
          };
        };
    }
    {
      at = userIn ren.kinds.mac;
      into = { user, ... }: ms: { darwin.home-manager.users.${sw.loginOf user}.imports = ms; };
    }
    {
      at = userIn ren.kinds.home;
      into =
        { home, ... }:
        ms: {
          homeConfigurations.${home.name} = inputs.home-manager.lib.homeManagerConfiguration {
            extraSpecialArgs.lib = home.system.legacyPackages.lib;
            modules = [ (nodeModule home "home") ] ++ ms;
            pkgs = import inputs.nixpkgs {
              config.allowUnfree = true;
              system = home.system.name;
            };
          };
        };
    }
    {
      at = userIn ren.kinds.droid;
      into =
        { droid, ... }:
        ms: {
          droid.home-manager = {
            config.imports = [
              (nodeModule droid "android")
              { home.stateVersion = "23.05"; }
            ]
            ++ ms;
            extraSpecialArgs = {
              inherit (droid.system.legacyPackages) lib;
              nixosConfig = null;
            };
          };
        };
    }
  ];

  ren.classes.droid = {
    at = ren.kinds.droid;
    into =
      { droid, ... }:
      ms: {
        nixOnDroidConfigurations.${droid.name} = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = droid.system.legacyPackages;
          extraSpecialArgs.lib = droid.system.legacyPackages.lib;
          modules = ms;
        };
      };
  };
}
