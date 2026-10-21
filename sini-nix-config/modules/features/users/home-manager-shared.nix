# Shared home-manager config (the HM nixos module itself is imported by platforms/home-manager.nix).
{ ren, lib, inputs, ... }:
{
  ren.kinds.machine.users-home-manager-shared = ren.lib.opt (lib.types.submodule {
    options.useGlobalPkgs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Home-manager shares the host's nixpkgs — its overlays and config — instead
        of evaluating its own pkgs set. User-declared overlays project to the host
        (see the nixpkgs-overlays quirk); when false each user's home-manager
        collects its own overlays as before.
      '';
    };
  }) { };

  ren.aspects.users-home-manager-shared = {
    os =
      { host, ... }:
      {
        home-manager.useGlobalPkgs = host.users-home-manager-shared.useGlobalPkgs;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = ".hm-backup";
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.sharedModules = [
          {
            programs.home-manager.enable = true;
            home.enableNixpkgsReleaseCheck = false;
          }
        ];
      };

    nixos.home-manager.sharedModules = [
      (
        { osConfig, ... }:
        {
          home.stateVersion = osConfig.system.stateVersion;
          systemd.user.startServices = "sd-switch";
        }
      )
    ];

    darwin.home-manager.sharedModules = [
      (
        { lib, ... }:
        {
          home.stateVersion = lib.trivial.release;
        }
      )
    ];

    # homeManagerModules is delivered by its channel (channels/overlays-am.nix) straight into the user's hm imports.
  };
}
