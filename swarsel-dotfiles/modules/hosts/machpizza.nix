# machpizza: old hosts/darwin/x86_64-darwin/machpizza/default.nix
{ ren, ... }:
{
  ren.mac.machpizza = {
    system = ren.system.x86_64-darwin;
    users = [ ren.user.work ];
  };
  ren.aspects.machpizza = {
    at = ren.mac.machpizza;
    includes = [ ren.aspects.profile-darwin ];
    darwin =
      {
        config,
        lib,
        ...
      }:
      let
        inherit (config.repo.secrets.local) workUser;
      in
      {

        users.users.${workUser}.home = "/home/${workUser}";
        services.karabiner-elements.enable = true;

        home-manager.users.${workUser} = {
          swarselsystems = {
            flakePath = "/home/${workUser}/.dotfiles";
            homeDir = "/home/${workUser}";
            isBtrfs = false;
            isDarwin = true;
            isLaptop = true;
            mainUser = workUser;
          };
          home.username = lib.mkForce workUser;
        };

        system.primaryUser = workUser;
      };
  };
}
