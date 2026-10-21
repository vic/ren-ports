{ inputs, ... }:
{
  ren.aspects.app-messaging-telegram = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          inputs.ayugram-desktop.packages.${pkgs.stdenv.hostPlatform.system}.ayugram-desktop
        ];
      };
  };
}
