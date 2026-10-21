# scripts: system-update
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.shells-scripts.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe;
      inherit (addax) runIfCommandExists;
    in
    {
      home.packages = [
        (pkgs.writers.writeNuBin "system-update" /* nu */ ''
          # Update all system components.

          # System.

          ${getExe pkgs.nh} os switch --update
          # ${getExe pkgs.nh} home switch --update
          # nix flake update --flake ${config.home.homeDirectory}/.nixos-config

          ${runIfCommandExists "flatpak" /* sh */ ''
            flatpak update --assumeyes
          ''}

          # Utilities.

          ${getExe pkgs.television} update-channels
          ${getExe pkgs.tealdeer} --update
          ${getExe pkgs.intelli-shell} tldr fetch
          # if command -v pipx >/dev/null; then pipx upgrade-all; fi

          # Games.

          ${runIfCommandExists "protonup" "protonup"}

        '')
      ];
    };
}
