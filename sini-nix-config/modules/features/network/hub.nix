# The always-on Syncthing hub (uplink): ONE system daemon backing up every
# replicating user's dirs under /var/lib/syncthing/<user>/<dir>. It emits its own
# device record (broadcast to members) and receives each member's device and dir
# set; daemon config is in hub-daemon.nix. Gated on the isHub machine field.
# Identity is a host-level agenix secret (`syncthing-identity` generator).
{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
in
{
  ren.aspects.network-syncthing-hub = {
    # Daemon state + folder data survive the root wipe, OWNED by the syncthing
    # user so it can create the per-user folder roots; a plain string entry lands
    # root-owned ("permission denied" creating folder root).
    persist.directories = [
      {
        directory = "/var/lib/syncthing";
        user = "syncthing";
        group = "syncthing";
        mode = "0700";
      }
    ];

    # The hub's own device record, broadcast to every member. Self-gated on the
    # committed host identity sidecar (present once minted).
    syncthing-peers =
      { host, environment, ... }:
      let
        idFile = host.secretPath + "/syncthing-${host.name}.id";
      in
      lib.optionals (builtins.pathExists idFile) [
        {
          hostname = host.name;
          deviceId = builtins.readFile idFile;
          addresses = [
            "tcp://${host.name}.${environment.name}.${environment.domain}:22000"
            "tcp://${host.name}.ts.${environment.domain}:22000"
          ];
          isHub = true;
        }
      ];

    nixos =
      { host, config, lib, ... }:
      lib.mkIf host.network-syncthing-settings-isHub {
        age.secrets.syncthing-hub-identity = {
          rekeyFile = host.secretPath + "/syncthing-${host.name}.age";
          generator.script = "syncthing-identity";
          owner = "syncthing";
          group = "syncthing";
        };

        # Sync port on the trusted tailnet interface only.
        networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
          22000
        ];
      };
  };
}
