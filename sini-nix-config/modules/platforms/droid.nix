# droid class: nix-on-droid machines build nixOnDroidConfigurations (Q7: own kind, no exclude policy).
{ ren, inputs, ... }:
let
  # inert shims absorbing options nix-on-droid lacks (den batteries hostname/hostPlatform emissions)
  shim =
    droid:
    { lib, ... }:
    {
      options.nixpkgs.hostPlatform = lib.mkOption {
        type = lib.types.raw;
        default = droid.system.name;
      };
      options.networking.hostName = lib.mkOption {
        type = lib.types.str;
        default = droid.name;
      };
    };
in
{
  ren.classes.droid = {
    at = ren.kinds.droid;
    into =
      { droid, ... }:
      ms: {
        nixOnDroidConfigurations.${droid.name} = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          # nix-on-droid ignores nixpkgs.config: set allowUnfree on the instance
          pkgs = import droid.channel.nixpkgs {
            system = droid.system.name;
            overlays = [ inputs.nix-on-droid.overlays.default ];
            config.allowUnfree = true;
          };
          modules = [ (shim droid) ] ++ ms;
          home-manager-path = droid.channel.home-manager.outPath;
        };
      };
  };
}
