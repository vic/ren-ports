# State versions every host and home starts from, and how home-manager runs inside nixos.
{ ren, ... }:
{
  ren.aspects.nixos-defaults = {
    at = ren.kinds.host;
    nixos = {
      system.stateVersion = "26.11";
      home-manager = {
        backupFileExtension = "backup";
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };
  };
  ren.aspects.home-defaults = {
    at = ren.kinds.user;
    homeManager = {
      home.stateVersion = "26.11";
      programs.home-manager.enable = true;
      systemd.user.startServices = "sd-switch";
    };
  };
}
