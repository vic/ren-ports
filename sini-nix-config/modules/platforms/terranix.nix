# terranix class (R:589): DNS records, at the environment that owns the public IP.
# The UniFi sibling class is flake/terranix/unifi-class.nix.
{ ren, inputs, ... }:
let
  inherit (ren.lib) and when;
in
{
  ren.classes.terranix = {
    at = and [
      ren.kinds.environment
      (when (r: r.environment.dns.publicIPv4 != null))
    ];
    into =
      { environment, ... }:
      ms: {
        terranixConfigurations."dns-${environment.name}" = inputs.terranix.lib.terranixConfiguration {
          system = "x86_64-linux";
          modules = ms;
        };
      };
  };
}
