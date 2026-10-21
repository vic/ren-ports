# Engine-agnostic containers/image config surface (~/.config/containers/ files read by podman, buildah, skopeo).
# Included by the podman aspect; rendered into the user (rootless) scope in containers-home.nix.
# Only `registries` ships a non-empty default; the rest are opt-in (never inject stale CNI/storage/policy config).
{
  ren,
  lib,
  ...
}:
{
  ren.kinds.machine.virtualization-containers = ren.lib.opt (lib.types.submodule {
    options = {
      registries = lib.mkOption {
        type = with lib.types; attrsOf (listOf str);
        default = {
          search = [
            "docker.io"
            "quay.io"
          ];
        };
        description = ''
          Registry resolution policy keyed by class (`search`, `insecure`,
          `block`), rendered to registries.conf in **v2** format: `search`
          populates `unqualified-search-registries`; `insecure`/`block` become
          per-registry `[[registry]]` entries. (NixOS's
          virtualisation.containers module emits the legacy v1 layout, which
          current skopeo rejects with "registries.conf must be in v2 format but
          is in v1" — hence the dedicated renderer.)
        '';
      };

      containersConf = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = { };
        description = ''
          containers.conf settings. Rendered only when non-empty. Defaults to
          empty because podman 5.x here uses netavark, not the CNI defaults the
          upstream module ships.
        '';
      };

      storage = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = { };
        description = ''
          storage.conf settings for the rootless store. Rendered only when
          non-empty: the system graphroot (zfs/overlay/impermanence) is owned by
          the podman aspect and uses a different root than rootless, so it must
          not be mirrored here.
        '';
      };

      policy = lib.mkOption {
        type = with lib.types; attrsOf anything;
        default = { };
        description = ''
          Signature verification policy.json. Rendered only when non-empty;
          otherwise rootless tools fall back to the system policy.
        '';
      };
    };
  }) { };

  # Push credentials for the private registry via the age-secrets channel (collected into HOST agenix).
  # The cleartext password is decrypted from the prod-env rekeyFile shared with the registry host and
  # k3s nodes; auth.json is generated from it via the container-auth generator.
  ren.aspects.virtualization-containers.age-secrets =
    { host, environment, ... }:
    {
      age.secrets = {
        # Pinned to the prod env path (where the registry lives), not this host's env secretPath.
        registry-password = {
          rekeyFile = ../../../.secrets/env/prod/registry/registry-password.age;
          generator.script = "rfc3986-secret";
        };

        # Generated ~/.config/containers/auth.json content, derived from the password above.
        # Owned by the system user so rootless podman/skopeo/buildah can read it through the home symlink.
        registry-auth = {
          rekeyFile = host.secretPath + "/registry-auth.age";
          generator.script = "container-auth";
          settings = {
            username = "builder";
            registry = ren.helpers.domainFor environment "registry";
          };
          owner = host.system-owner.name;
        };
      };

      # generator.dependencies reads class config, so it lives in a module inside imports.
      imports = [
        (
          { config, ... }:
          {
            age.secrets.registry-auth.generator.dependencies = [ config.age.secrets.registry-password ];
          }
        )
      ];
    };
}
