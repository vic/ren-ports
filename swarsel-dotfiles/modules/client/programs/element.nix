{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.element.homeManager =
    {
      globals-defs,
      ...
    }:
    let
      globals = sw.globalsOf globals-defs;
    in
    {
    config = {
      swarselsystems.enabledHomeModules = [ "element-desktop" ];
      programs.element-desktop = {
        enable = true;
        settings = {
          UIFeature = {
            deactivate = false;
            feedback = false;
            passwordReset = false;
            registration = false;
            shareSocial = false;
            voip = false;
            widgets = false;
          };
          default_server_config."m.homeserver".base_url = "https://${globals.services.matrix.domain}/";
        };
      };
    };
  };
}
