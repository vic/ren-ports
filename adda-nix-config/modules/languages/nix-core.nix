# nix-core: Determinate Nix, direnv and envoluntary prerequisites (split from languages-nix so servers can take them alone).
{ ren, inputs, ... }:
let
  addax = ren.helpers;
in
{
  # The part of the Nix tooling that is a prerequisite rather than a preference.
  #
  # `addax.languages.nix` (the full aspect) is a nixpkgs-maintainer toolkit: nixd, nil,  omnix, nix-init,
  # nixpkgs-review, nix-update, nix-tree, devenv, comma and the nix-index database, the nom wrappers. None of that
  # belongs on a server, but three things underneath it are load-bearing everywhere and are split out here so
  # `addax.addaServer` can take them alone:
  #   - Determinate Nix, which is the Nix this repo is written against (every host runs it, and `lazy-trees` below is
  #     one of its settings);
  #   - `programs.envoluntary`, which the nushell config reads as `config.programs.envoluntary.package`;
  #   - direnv, which is how any project shell is entered at all.
  #
  # The full aspect includes this one, so a workstation sees exactly what it saw when all of it lived in one file.

  ren.aspects.languages-nix-core.os = {
    imports = [
      inputs.omniflake.pinned.determinate.nixosModules.default
    ];

    # Determinate Nix only. Upstream nix rejects the setting outright.
    nix.settings.lazy-trees = true;

    # Has to travel with the home-manager module below, not with the maintainer toolkit. Without it
    # `programs.envoluntary.package` falls back to nixpkgs' envoluntary, whose `shell export`/`shell hook` subcommands
    # accept only bash/fish/json/zsh. The nushell config calls both with `nushell`, so every interactive shell on such a
    # host opened with two "error: invalid value 'nushell' for '<SHELL>'" lines and no envoluntary integration.
  };

  # Overlay emission (old: nixos nixpkgs.overlays); the host applies it. Comment above explains why it travels with this aspect.
  ren.aspects.languages-nix-core.overlays =
    { ... }: inputs.omniflake.unified.envoluntary.overlays.default;

  ren.aspects.languages-nix-core.homeManager = {
    imports = [
      inputs.omniflake.unified.direnv-instant.homeModules.direnv-instant
      inputs.omniflake.unified.envoluntary.homeModules.default
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global = {
        warn_timeout = 0;
        # Silence direnv's success chatter ("loading ~/…/.envrc", "using flake", "nix-direnv: Using cached dev shell",
        # the giant "export +AR +AS …" diff) on every activation. `log_filter` is a *whitelist* regex, and direnv applies
        # it only in `logStatus`; `logError` ignores both it and `log_format`, so genuine errors (blocked .envrc, failed
        # build) still print. `^$` never matches a status message. `log_format = ""` would work too, but only from the
        # environment: direnv's config loader ignores empty toml strings.
        log_filter = "^$";
      };
      # https://github.com/direnv/direnv/wiki/Customizing-cache-location#human-readable-directories.
      stdlib = ''
        : "''${XDG_CACHE_HOME:="''${HOME}/.cache"}"
        declare -A direnv_layout_dirs
        direnv_layout_dir() {
            local hash path
            echo "''${direnv_layout_dirs[$PWD]:=$(
                hash="$(sha1sum - <<< "$PWD" | head -c40)"
                path="''${PWD//[^a-zA-Z0-9]/-}"
                echo "''${XDG_CACHE_HOME}/direnv/layouts/''${hash}''${path}"
            )}"
        }
      '';
    };

    programs.git.ignores = [
      ".direnv/"
      ".devenv/"
    ];

    programs.direnv-instant = {
      enable = true;
      enableFishIntegration = false;
      enableBashIntegration = false;
    };

    programs.envoluntary = {
      enable = true;

      # config = {
      #   entries =
      #     lib.map
      #       (path: {
      #         pattern = path;
      #         flake_reference = path;
      #       })
      #       [
      #         "~/documents/it/nixos/nixpkgs-pkgs-update"
      #         "~/documents/it/nixos/nixpkgs"
      #       ];
      # };
    };

    nix.settings = {
      show-trace = true;
    };
  };

  ren.aspects.languages-nix-core.abbreviations =
    { pkgs, ... }:
    let
      inherit (addax) getExeName;
    in
    with pkgs;
    {
      # Nix development.
      n = "nix";
      nr = "nix run";
      nf = "nix fmt";
      nb = "nix build";
      nd = "nix develop";
      ns = "nix shell";
      su = "system-update";
      sc = "system-clean";
      nfu = "nix flake update";
      nfc = "nix flake check --impure";
      nrd = "nix-run-dot";
      nrn = "nix-run-nixpkgs";
      nhh = "${getExeName pkgs.nh} home switch -- --impure";
      shl = "nix-shell-with";
      # nhs = "nh search $@ | bat";
      nhs = "${getExeName pkgs.nh} search";
      tvn = "${getExeName pkgs.television} nix-search-tv";
      man = "man-tv";
      nho = "${getExeName pkgs.nh} os switch -- --impure";
      nhb = "${getExeName pkgs.nh} os build -- --impure";
      nrp = "${getExeName nixpkgs-reviewFull} pr";
      nrpr = "${getExeName nixpkgs-reviewFull} post-result";
      da = "${getExeName direnv} allow";
      dr = "${getExeName direnv} reload";
      de = "${getExeName devenv} devenv";
      dep = "${getExeName devenv} processes";
      det = "${getExeName devenv} test";
      dett = "${getExeName devenv} tasks";
    };
}
