# Syncthing `member` collector: when a user replicates, mint a per-(user,host)
# device identity (home-manager agenix secret; the `syncthing-identity` generator
# lives in the secrets `_generators-module.nix`) and run that user's
# services.syncthing wired to the same-user peer mesh. Replicated dirs stay
# persisted via the claude aspect's persistHome; system/firewall content is the
# user-scoped `peer` aspect.
{ ... }:
{
  ren.aspects.network-syncthing-member-homeManager.homeManager =
    {
      replicateHome,
      syncthing-peers,
      user,
      host,
      lib,
      config,
      ...
    }:
    let
      dirs = lib.unique (lib.concatMap (e: e.directories or [ ]) replicateHome);
      home = config.home.homeDirectory;
      versioningFor = import ./_syncthing-versioning.nix;
      folderId = p: "stfolder-" + builtins.hashString "sha256" "${user.name}:${p}";
      # Delivered peers are already same-user; drop self and any without a device id.
      sharePeers = lib.filter (
        q: q.hostname != host.name && (q.deviceId or null) != null
      ) syncthing-peers;
      # The daemon runs only inside a mesh (another non-hub host of this user).
      # The identity is minted regardless: its `.id` is what puts this host in
      # `syncthing-peers` for the user's other hosts; gating it too would leave a
      # user's first two hosts each waiting on the other.
      inMesh = lib.any (q: !(q.isHub or false)) sharePeers;
    in
    lib.mkIf (dirs != [ ]) {
      age.secrets.syncthing-identity = {
        rekeyFile = user.secretPath + "/syncthing-${host.name}.age";
        generator.script = "syncthing-identity";
      };

      services.syncthing = lib.mkIf inMesh {
        enable = true;
        overrideDevices = true;
        overrideFolders = true;
        # Per-user unix socket in the XDG cache dir: cross-platform, space-free,
        # parent always exists. A leading-`/` path makes the HM module prepend
        # `unix://` and reuse the path for its config-apply curl.
        guiAddress = "${config.xdg.cacheHome}/syncthing.sock";
        # Public cert as its own store path: a flake-source path makes the whole
        # `-source` the dep, which colmena's derivation rewrite drops from the
        # copied closure, so the cert never reaches remote members.
        cert = "${builtins.path {
          path = user.secretPath + "/syncthing-${host.name}.crt";
          name = "syncthing-${host.name}.crt";
        }}";
        key = config.age.secrets.syncthing-identity.path;
        settings = {
          # Fully declarative mesh: no discovery, no relays; only the sync port listens.
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
            ) sharePeers
          );
          folders = lib.listToAttrs (
            map (
              p:
              lib.nameValuePair (folderId p) {
                id = folderId p;
                # Relative dir; `peer` broadcasts these so the hub mirrors each
                # folder at /var/lib/syncthing/<user>/<p>.
                label = p;
                path = "${home}/${p}";
                devices = map (q: q.hostname) sharePeers;
                versioning = versioningFor p;
              }
            ) dirs
          );
        };
      };
    };
}
