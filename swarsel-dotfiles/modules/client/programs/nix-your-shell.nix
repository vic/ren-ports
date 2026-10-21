{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.nix-your-shell.homeManager =
    let
      moduleName = "nix-your-shell";
    in
    {
      config = {
        swarselsystems.enabledHomeModules = [ "nix-your-shell" ];
        programs.${moduleName} = {
          enable = true;
          enableZshIntegration = true;
        };
      };
    };
}
