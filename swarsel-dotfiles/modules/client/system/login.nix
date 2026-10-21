{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.login.flake-inputs.noctalia-greeter = {
    inputs.nixpkgs.follows = "nixpkgs";
    url = "github:noctalia-dev/noctalia-greeter";
  };

  ren.aspects.login.nixos =
    {
      globals-defs,
      host,
      config,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
      confLib = sw.confLibOf { inherit host globals config; };
    in
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];
      config = {

        users.persistentIds.greeter = confLib.mkIds 958;
        services = {
          displayManager.noctalia-greeter.enable = true;
          greetd = {
            enable = true;
            settings.initial_session.command = "uwsm start -- niri-uwsm.desktop";
          };
        };
        environment = {
          pathsToLink = [ "/share/wayland-sessions" ];
          systemPackages = config.services.displayManager.sessionPackages;
        };

      };
    };
}
