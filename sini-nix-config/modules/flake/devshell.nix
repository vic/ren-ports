# devshell: maintainer shell (devShells.<sys>.default), numtide/devshell.
# Content is a devshell class module (platforms/devshell.nix); other aspects at system add packages/commands/startup to it.
{ ren, inputs, ... }:
let
  lib = inputs.nixpkgs.lib; # module-level lib fns are nixpkgs-only (fleet lib is ren.genLib)
  cmd = package: help: { inherit package help; };
  # sini config.packages.* scripts (pkgs/by-name): name -> help
  scripts = {
    nix-flake-update = "Update flake inputs with GitHub access token";
    update-pkgs = "Update custom package sources via nix-update";
    publish-sites = "Sync sites/<domain>/ to its Garage website bucket ([--dry-run] [domain...])";
    list-infra = "List all flake environments and hosts with details";
    nix-flake-build = "Build a host configuration";
    update-host-keys = "Collect and encrypt SSH host keys from all configured hosts";
    nix-flake-provision-keys = "Provision SSH host keys and disk encryption secrets for a NixOS host";
    nix-flake-install = "Install NixOS remotely using nixos-anywhere with SSH keys and disk encryption";
    impermanence-copy = "Copy existing data to impermanence persistent storage for a host";
    matrix-bot-provision = "Join @genie to a room with its agenix-generated token; prints the rooms setting";
    update-tang-disk-keys = "Update disk encryption keys using Tang servers and TPM2";
  };
in
{
  ren.aspects.flake-devshell = {
    at = ren.kinds.system;
    flake-inputs =
      { ... }:
      {
        devshell = {
          url = "github:numtide/devshell";
          inputs.nixpkgs.follows = "nixpkgs-unstable";
        };
      };
    devshell =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        # the by-name packages (flake/pkgs.nix), read lazily from the flake
        local = inputs.self.packages.${system.name};
      in
      {
        packages = [
          pkgs.git
          pkgs.gh
          pkgs.nix # the flake's nix, so nix-plugins matches
          pkgs.nixos-rebuild
          pkgs.nix-output-monitor
          pkgs.nix-fast-build
          pkgs.nil
          pkgs.nixd
          pkgs.sops
          local.gen-lsp-mcp # gen-lsp MCP enumeration server (registered in .mcp.json for this fleet)
        ]
        ++ lib.optionals pkgs.stdenv.buildPlatform.isDarwin [
          pkgs.coreutils-full # GNU coreutils on darwin
        ];
        commands = [
          (cmd pkgs.nh "Nix helper for nixpkgs development")
          (cmd inputs.self.formatter.${system.name} "Format all files")
          (cmd pkgs.nix-tree "Interactively browse dependency graphs of Nix derivations")
          (cmd pkgs.nvd "Diff two nix toplevels and show which packages were upgraded")
          (cmd pkgs.nix-diff "Explain why two Nix derivations differ")
          (cmd pkgs.nix-output-monitor "Nix Output Monitor (a drop-in alternative for `nix` which shows a build graph)")
        ]
        ++ lib.mapAttrsToList (name: help: {
          package = local.${name};
          inherit name help;
        }) scripts;
      };
  };
}
