{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.autologin.nixos =
    {
      config,
      ...
    }:
    let
      inherit (config.swarselsystems) mainUser;
    in
    {
      config.services = {
        getty.autologinUser = mainUser;
        greetd.settings.initial_session.user = mainUser;
      };
    };
}
