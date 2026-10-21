# readme fragment: ren (order 30). Describes this repo's Ren layout; replaces sini docs/den.nix.
{ ren, ... }:
{
  ren.aspects.docs-ren = {
    at = ren.fleet.sini;
    readme = {
      order = 30;
      text = ''
        ## Architecture

        This repository is a [Ren](https://github.com/vic/ren) fleet.
        A fleet is a tree of typed instances (kinds).
        Aspects attach config to the instances they match.
        Classes turn that config into flake outputs.

        ### Kinds

        Kinds live in `modules/topology`, one file per kind.

        | Kind | Purpose |
        | :--- | :--- |
        | `fleet` | Root of the tree. One instance: `sini`. |
        | `system` | Per-system outputs (x86_64-linux, aarch64-linux, aarch64-darwin). |
        | `channel` | Data: nixpkgs, home-manager and nix-darwin triple, plus the system builders. |
        | `environment` | Domain, networks, certs, delegation, services (prod, dev). |
        | `group` | Membership labels and members. Used for access control. |
        | `machine` | Abstract: system, channel, environment, owner, facts, exporters. |
        | `host` | A NixOS machine. Is a `machine`. |
        | `guest` | A microvm guest. Is a `host`. |
        | `mac` | A nix-darwin machine. Is a `machine`. |
        | `droid` | A nix-on-droid machine. Is a `machine`. |
        | `user` | Identity (SSH, GPG), uid, groups. |
        | `cluster` | A k8s cluster: role, version, hosts, networks. |
        | `domain` | A DNS zone with its DNS, TLS, web and mail data. |

        ### Scope Tree

        Each instance sits under a parent kind (`below`). Aspects and classes match by kind.

        ```
        fleet
         +-> environment
         |   +-> host / mac / droid
         |   |   +-> user
         |   |   +-> guest (host field `guests`)
         |   +-> cluster
         +-> domain
         +-> system
        ```

        Users reach a machine through `ren.helpers.usersOf` (group closure plus environment and host gates).
        Macs and droids list their users in a `users` field.

        ### How a host gets its config

        1. The host is an instance in `modules/hosts/<h>/<h>.nix`, for example `ren.host.uplink`.
           It sets `system`, `channel`, `environment`, `system-owner`, `system-access-groups`, networking and per-aspect settings.
        2. A same-named aspect, `ren.aspects.<h>`, has `at = ren.host.<h>`.
           Its `includes` list pulls in roles and features.
        3. Roles (`modules/roles`) are aspects that only have `includes`. The `default` role applies to every machine.
        4. Features (`modules/features`) emit class keys: `nixos`, `darwin`, `homeManager`, and others.
        5. Channels (`modules/channels`) carry data between instances. Aspects emit into them. Receivers read them.
        6. The `nixos` class (`modules/platforms/nixos.nix`) collects all modules for a metal host.
           It builds `nixosConfigurations.<h>` with the host's `channel.nixosSystem`.
           It also emits `colmena-nodes.<h>` for the colmena hive.

        ### Classes

        Classes live in `modules/platforms`. A class says where its modules go.

        | Class | Output |
        | :--- | :--- |
        | `nixos` | `nixosConfigurations` for metal hosts. Microvm guests forward into `microvm.vms` on the parent host. |
        | `darwin` | `darwinConfigurations` for macs. |
        | `droid` | `nixOnDroidConfigurations` for droids. |
        | `os` | Shared config forwarded into `nixos` or `darwin`. |
        | `homeManager`, `homeLinux`, `homeDarwin` | home-manager users on each machine. The latter two select by system suffix. |
        | `account` | `users.users` entries. |
        | `k8s-manifests` | nixidy environments per cluster. |
        | `terranix` | Terranix modules (DNS, GitHub, UniFi). |
        | `panix` | Panix node modules. |
        | `devshell` | `devShells.<system>.default`. |
        | `packages`, `apps`, `checks`, `legacyPackages`, `chartsDerivations`, `imagesDerivations` | Per-system outputs. |
        | `treefmt` | Formatter config. |
        | `files` | Generated repo files: README, LICENSE, `.gitignore`, `.sops.yaml`. |

        ### Channels

        Channels live in `modules/channels`, grouped by family in files named `<family>-am.nix` and `<family>-nz.nix`.
        Families: agents, darwin, deploy, discovery, dns, edge, editors, flake, k8s, mesh, monitoring, overlays, secrets, storage, sync, unfree.
        Examples: `persist`, `firewall`, `age-secrets`, `nixpkgs-overlays`, `host-addrs`, `colmena-nodes`, `readme`.

        ### Helpers

        Helpers live in `modules/helpers`, one file per helper, as `ren.helpers.<name>`.
        Examples: `usersOf`, `groupClosure`, `setting`, `ipv4Of`, `ipv6Of`, `deployment`, `domainFor`, `clusterOf`, `sopsAgeRecipient`, `repo`.

        ### Settings

        A feature setting is one typed field on the kind that reads it, named like the aspect.
        An instance sets it in its own file, for example `svc-bgp.localAsn` on `ren.host.uplink`.
        `ren.helpers.setting` reads the nearest value, host first, then environment.

        ### Directory Layout

        ```
        modules/
        +-- topology/       Kind definitions (fleet, system, channel, environment, group, machine, host, guest, mac, droid, user, cluster, domain)
        +-- platforms/      Class definitions (nixos, darwin, droid, homeManager, k8s, terranix, panix, files, ...)
        +-- channels/       Data channels between aspects and receivers
        +-- helpers/        Shared functions: ren.helpers.<name>
        +-- features/       Aspects, one directory per capability (boot, disk, hardware, desktop, apps, dev, services, k8s, ...)
        +-- roles/          Named bundles of features (default, server, workstation, dev, gaming, ...)
        +-- hosts/<h>/      One host, mac, droid or guest instance plus its aspect
        +-- people/         User instances
        +-- environments/   Environment instances (prod, dev) and groups/
        +-- clusters/       Cluster instances (axon)
        +-- domains/        Domain instances, one file per zone
        +-- flake/          Flake wiring: inputs, systems, pkgs, treefmt, devshell, terranix/, meta
        +-- docs/           README fragments and generated files
        ```

      '';
    };
  };
}
