# Hub services.syncthing: devices from member emits, one folder per
# (user, replicated dir) mirrored under /var/lib/syncthing/<user>/<dir>.
{ ... }:
{
  ren.aspects.network-syncthing-hub.nixos =
    {
      syncthing-peers,
      replicateHome,
      host,
      config,
      lib,
      ...
    }:
    let
      dataDir = "/var/lib/syncthing";
      versioningFor = import ./_syncthing-versioning.nix;
      # Member device records (drop self + id-less + the hub's own emit).
      members = lib.filter (
        q: q.hostname != host.name && (q.deviceId or null) != null && (q.user or null) != null
      ) syncthing-peers;
      # Dir broadcasts arrive once per (user, host); dedup to a per-user set.
      users = lib.unique (map (r: r.user) replicateHome);
      dirsForUser =
        u: lib.unique (lib.concatMap (r: r.directories or [ ]) (lib.filter (r: r.user == u) replicateHome));
      hostsForUser = u: lib.unique (map (q: q.hostname) (lib.filter (q: q.user == u) members));
      folderId = u: p: "stfolder-" + builtins.hashString "sha256" "${u}:${p}";
    in
    lib.mkIf host.network-syncthing-settings-isHub {
      services.syncthing = {
        enable = true;
        inherit dataDir;
        overrideDevices = true;
        overrideFolders = true;
        # Public cert as its own store path (a real runtime dep that reaches the
        # host, unlike a flake-source path) - same as the member.
        cert = "${builtins.path {
          path = host.secretPath + "/syncthing-${host.name}.crt";
          name = "syncthing-${host.name}.crt";
        }}";
        key = config.age.secrets.syncthing-hub-identity.path;
        settings = {
          # Fully declarative mesh: addressed peers only, no discovery/relays.
          options = {
            globalAnnounceEnabled = false;
            localAnnounceEnabled = false;
            relaysEnabled = false;
          };
          devices = lib.listToAttrs (
            map (
              q:
              lib.nameValuePair q.hostname {
                id = q.deviceId;
                inherit (q) addresses;
              }
            ) members
          );
          folders = lib.listToAttrs (
            lib.concatMap (
              u:
              map (
                p:
                lib.nameValuePair (folderId u p) {
                  id = folderId u p;
                  label = "${u}/${p}";
                  path = "${dataDir}/${u}/${p}";
                  devices = hostsForUser u;
                  versioning = versioningFor p;
                }
              ) (dirsForUser u)
            ) users
          );
        };
      };
    };
}
