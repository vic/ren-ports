# home-manager: host settings for the homes, and the modules every home imports.
{ ren, inputs, ... }:
{
  # home-manager on a NixOS host: the homes come from the homeManager class (platforms/home-manager.nix)
  ren.aspects.home-manager.nixos =
    { config, lib, ... }:
    let
      inherit (config.swarselsystems) isMicroVM isServer mainUser;
      homeSwarsel = config.home-manager.users.${mainUser}.swarselsystems or { };
    in
    {
      config = {
        sops = {
          secrets = lib.mapAttrs (_: v: v // { owner = mainUser; }) (homeSwarsel.homeSopsSecrets or { });
          templates = lib.mapAttrs (_: v: v // { owner = mainUser; }) (homeSwarsel.homeSopsTemplates or { });
        };
        home-manager = lib.mkIf (!isServer && !isMicroVM) {
          backupFileExtension = "hm-bak";
          extraSpecialArgs = {
            inherit (inputs) nixgl;
            inherit lib;
          };
          overwriteBackup = true;
          useGlobalPkgs = true;
          useUserPackages = true;
          verbose = true;
        };
      };
    };

  ren.aspects.home-manager.darwin = {
    home-manager.extraSpecialArgs = {
      inherit (inputs) nixgl;
    };
  };

  # every home on a NixOS host or a mac (old `home-manager.users.<mainUser>.imports`)
  ren.aspects.home-manager-base.at = ren.kinds.user;
  ren.aspects.home-manager-base.homeManager =
    {
      osConfig ? null,
      lib,
      ...
    }:
    {
      imports = [
        inputs.swarsel-nix.homeModules.default
        inputs.glide-nix.homeModules.default
      ];
      home.stateVersion = lib.mkDefault (if osConfig == null then "23.05" else osConfig.system.stateVersion);
    };

}
