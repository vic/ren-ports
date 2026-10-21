{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.pedantix.homeManager =
    {
      lib,
      ...
    }:
    {
      imports = lib.optionals (inputs ? pedantix && inputs.pedantix ? homeModules) [
        inputs.pedantix.homeModules.default
        {
          swarselsystems.enabledHomeModules = [ "pedantix" ];
          programs.pedantix = {
            enable = true;
            settings = import "${inputs.self}/files/nix/pedantix-settings.nix";
          };
        }
      ];
    };
}
