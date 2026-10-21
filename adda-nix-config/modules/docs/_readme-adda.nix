# readme adda (a fn of ren and lib): how this repo uses Ren; every name below is a file or option in modules/ (checked by grep when written).
{ ren, lib }:
let
  # work hosts: those whose VM console autologs into the work identity
  workHosts = lib.sortOn (name: name) (
    map (host: host.name) (
      builtins.filter (host: host.vmAutologin != null && host.vmAutologin.name == ren.user.ichocholaty.name) (
        builtins.attrValues ren.host
      )
    )
  );
in
''
  ## How Adda uses Ren

  **Kinds hold typed facts.** Aspects read the facts. They do not read each other.

  - `host` ([topology/host.nix](modules/topology/host.nix)) has `workstation`, `signingKey`, `cpuPower`, `swap`, `ttyAutologin` and `vmAutologin`.
  - `user` ([topology/user.nix](modules/topology/user.nix)) has `nick`, `realName`, `vcs`, `editors`, `aiRules` and `authorizedKeys`.
  - `fleet` ([topology/fleet.nix](modules/topology/fleet.nix)) has `tailnet`, `upstreamDns`, `plainDns` and `ci`. One fleet, `addax`, owns the tailnet. No host reads another host's user for it.

  **Invalid states do not exist.**

  - `swap` is a record: `zram`, `swapspace` and `swapfile`. `zswap` is a field of `swapfile`. A host cannot have zswap without a swapfile.
  - `cpuPower` is an enum: `auto-cpufreq` or `watt`. A host picks one. No assertion checks for two handlers.
  - `ttyAutologin` and `vmAutologin` hold a user, not a string. A name that is not a user does not evaluate.

  **Two users, two identities.** `adda` is the personal user. `ichocholaty` is the work identity on ${lib.concatMapStringsSep " and " (name: "`${name}`") workHosts}. It is its own `ren.user`, with its own aspect at it. The `workstation` aspect is on only where `ren.user.adda` is on a host with `workstation = true`.

  **Classes route user content.**

  - `os` writes NixOS config from a user aspect into the host.
  - `account` writes `users.users.<login>`.
  - `homeManager` writes the home of a user inside the host.
  - `aliases` and `abbreviations` write shell aliases and abbreviations (fish, nushell, zsh) into home-manager.
  - `helixSettings`, `helixLanguages`, `helixPackages`, `zedSettings`, `zedPackages` and `vscodiumSettings` let a language aspect add editor settings. They merge in one home-manager option each ([editors/quirks.nix](modules/editors/quirks.nix)).

  **Channels move data between scopes.**

  - `zed-extensions` and `vscodium-extensions`: a user emits extension ids. The editor aspect reads the whole set.
  - `overlays`: a host or user emits nixpkgs overlays. The host applies them once.
  - `service-domains`: a service emits a function of the realized NixOS config. Caddy calls each function and builds the reverse proxy from the results.
  - `packages`: a system emits flake packages. Content reads them back with the `selfPackages` helper ([helpers.nix](modules/helpers.nix)).
  - `flake-inputs`: any scope names flake inputs. The `flake-file` class writes them to `flake.nix`.
''
