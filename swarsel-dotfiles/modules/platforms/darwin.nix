# nix-darwin: one darwin system per mac and variant (old mkDarwinHost).
{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.classes.darwin = {
    at = ren.kinds.mac;
    into =
      { mac, variant, ... }:
      ms:
      let
        output =
          if variant.minimal then "darwinConfigurationsMinimal" else "darwinConfigurations";
      in
      {
        ${output}.${mac.name} = inputs.nix-darwin.lib.darwinSystem {
          specialArgs.lib = mac.system.legacyPackages.lib;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            (
              { lib, ... }:
              {
                node = {
                  arch = lib.mkForce mac.system.name;
                  name = lib.mkForce mac.name;
                  secretsDir = inputs.self + "/hosts/darwin/${mac.system.name}/${mac.name}/secrets";
                  type = lib.mkForce "darwin";
                };
                swarselsystems.mainUser = sw.loginOf (builtins.head mac.users);
              }
            )
          ]
          ++ ms;
        };
      };
  };
}
