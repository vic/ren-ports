# containers: render each configured file into the user scope. Rootless podman/buildah/skopeo read
# ~/.config/containers/* in preference to /etc, so this fixes rootless tooling without touching /etc.
{ ... }:
{
  ren.aspects.virtualization-containers.homeManager =
    {
      host,
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      cfg = host.virtualization-containers;
      toml = (pkgs.formats.toml { }).generate;

      registriesV2 = toml "registries.conf" (
        {
          unqualified-search-registries = cfg.registries.search or [ ];
        }
        //
          lib.optionalAttrs ((cfg.registries.insecure or [ ]) != [ ] || (cfg.registries.block or [ ]) != [ ])
            {
              registry =
                map (location: {
                  inherit location;
                  insecure = true;
                }) (cfg.registries.insecure or [ ])
                ++ map (location: {
                  inherit location;
                  blocked = true;
                }) (cfg.registries.block or [ ]);
            }
      );
    in
    {
      home.packages = with pkgs; [
        skopeo
        buildah
      ];

      xdg.configFile = lib.mkMerge [
        { "containers/registries.conf".source = registriesV2; }
        # Generated push credentials: out-of-store symlink to the HOST agenix secret's decrypted
        # runtime path (the auth.json IS the secret; no activation script writes it).
        {
          "containers/auth.json".source =
            config.lib.file.mkOutOfStoreSymlink osConfig.age.secrets.registry-auth.path;
        }
        (lib.mkIf (cfg.containersConf != { }) {
          "containers/containers.conf".source = toml "containers.conf" cfg.containersConf;
        })
        (lib.mkIf (cfg.storage != { }) {
          "containers/storage.conf".source = toml "storage.conf" cfg.storage;
        })
        (lib.mkIf (cfg.policy != { }) {
          "containers/policy.json".source = pkgs.writeText "policy.json" (builtins.toJSON cfg.policy);
        })
      ];
    };
}
