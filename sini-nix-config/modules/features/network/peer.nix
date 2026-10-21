# Per-user `peer` aspect: advertise this user's Syncthing device to the same-user
# mesh and open its sync port. Both gate on the committed `.id` sidecar (present
# iff the user replicates, written by the member secret generator).
# Placed on every user (den: schema.user.includes).
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.network-syncthing-peer = {
    at = ren.kinds.user;

    # Self-gates as a list: emissions are forced eagerly, so a bare `readFile` of a
    # missing `.id` would throw; `pathExists` is lazy, so an absent sidecar is `[]`.
    syncthing-peers =
      {
        host,
        user,
        environment,
        ...
      }:
      let
        idFile = user.secretPath + "/syncthing-${host.name}.id";
        port = toString (22000 + ren.helpers.syncthingOffsetOf user);
      in
      lib.optionals (builtins.pathExists idFile) [
        {
          hostname = host.name;
          user = user.name;
          deviceId = builtins.readFile idFile;
          addresses = [
            "tcp://${host.name}.${environment.name}.${environment.domain}:${port}"
            "tcp://${host.name}.ts.${environment.domain}:${port}"
          ];
        }
      ];

    # Sync port open on the trusted tailnet interface only, never global.
    # den's user-scoped `nixos` branch is `os` in Ren.
    os =
      {
        host,
        user,
        config,
        lib,
        ...
      }:
      lib.mkIf (builtins.pathExists (user.secretPath + "/syncthing-${host.name}.id")) {
        networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
          (22000 + ren.helpers.syncthingOffsetOf user)
        ];
      };
  };
}
