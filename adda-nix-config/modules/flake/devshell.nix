# devshell: the maintainer shells (devShells.<sys>.default and .latex), numtide/devshell from omniflake.
{ ren, inputs, ... }:
let
  mkShell = pkgs: (import inputs.omniflake.unified.devshell { nixpkgs = pkgs; }).mkShell;
in
{
  ren.aspects.devshell-default = {
    at = ren.system.x86_64-linux;
    devshells =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
      in
      {
        default = mkShell pkgs {
          name = "adda-nixos-config-devshell";

          # https://numtide.github.io/devshell/modules_schema.html

          # FIXME: devenv's `languages.nix` / `languages.shell` toggles are not in devshell; their tools are listed.

          # enterShell = ''
          #   hello
          # '';

          packages = with pkgs; [
            # config.packages.hello
            nixfmt
            nixd
            statix
            deadnix

            yazi
            zellij
            git
            jujutsu
            jjui
            neovim
            dysk
            nh
            just

            opentofu # terraform/tailscale — the tailnet control plane (ACLs, DNS)
          ];
        };

        latex = mkShell pkgs {
          name = "latex-devshell";

          packages = with pkgs; [
            rubber
            gnumake
            just
            (texliveFull.withPackages (
              ps: with ps; [
                latexmk
                # latex-bin
                # scheme-full
              ]
            ))

            tex-fmt
            coreutils
            texlab
            tectonic
          ];
        };

        # packages.hello = pkgs.hello;
      };
  };
}
