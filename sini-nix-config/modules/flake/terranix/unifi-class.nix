# Terranix (OpenTofu) modules for the UniFi gateway, per environment, in
# unifiTerranixModules.<env>. Run `nix build .#unifi.config` for config.tf.json.
{ ren, ... }:
let
  inherit (ren.lib) and when;
in
{
  ren.classes.unifi-terranix = {
    at = and [
      ren.kinds.environment
      (when (r: r.environment.unifi != null))
    ];
    into =
      { environment, ... }:
      ms: {
        unifiTerranixModules.${environment.name} = ms;
      };
  };
}
