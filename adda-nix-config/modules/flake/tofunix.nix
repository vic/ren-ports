# tofunix: the tailnet's terraform configuration (terraform/tailscale/) generated from Nix via Tofunix.
# Typed provider options go through the nixpkgs module system instead of hand-written HCL. `nix run .#tofunix -- <plan|apply|...>`
#  works from anywhere in the repo: the wrapper below cds into terraform/tailscale/ (where the state and lock live) and
#  exports the sops-decrypted credentials when direnv has not already done so.
{ ren, inputs, ... }:
{
  ren.aspects.pkg-tofunix = {
    at = ren.system.x86_64-linux;
    packages =
      { system, ... }:
      let
        inherit (inputs.nixpkgs) lib;
        pkgs = system.legacyPackages;
        # The owner suffix is load-bearing: the bare `tofunix` index entry is cafkafk/tofunix,
        #  a different project; `tofunix-technofab11` is the github mirror of
        #  gitlab:TECHNOFAB/tofunix at the same revision.
        tofunix-lib = pkgs.callPackage "${inputs.omniflake.unified.tofunix-technofab11}/lib" { };

        tailscale-provider = tofunix-lib.mkOpentofuProvider {
          owner = "tailscale";
          repo = "tailscale";
          version = "0.29.2";
          hash = "sha256-241TJMn4UVCcnd2FZ4Oo1GlO9pZb14hofgWST1xYM2I=";
        };

        cli = tofunix-lib.mkCliAio {
          plugins = [ tailscale-provider ];
          moduleConfig = ../../terraform/tailscale/config.nix;
        };
      in
      {
        tofunix =
          (pkgs.writeShellScriptBin "tofunix" ''
            set -euo pipefail
            cd "$(${lib.getExe pkgs.git} rev-parse --show-toplevel)/terraform/tailscale"
            if [ -z "''${TAILSCALE_OAUTH_CLIENT_ID:-}" ]; then
              set -a
              eval "$(${lib.getExe pkgs.sops} -d ../../secrets/tailscale-terraform.env)"
              set +a
            fi
            exec ${cli}/bin/tofunix "$@"
          '')
          // {
            inherit (cli) module tfjson;
          };
      };
  };
}
