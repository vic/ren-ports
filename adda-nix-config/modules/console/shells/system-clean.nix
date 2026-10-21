# scripts: system-clean
{ ren, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.shells-scripts.homeManager =
    {
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe getExe';
      inherit (addax) runIfCommandExists;
    in
    {
      home.packages = [
        (pkgs.writers.writeNuBin "system-clean" /* nu */ ''
          # Clean up Nix store.
          ${getExe pkgs.nh} clean all
          # nix store gc --debug
          # nix-collect-garbage

          # paru -Scccd

          # Clean up podman/docker containers.
          ${getExe pkgs.podman} system prune --all --volumes #--force

          # Keep system logs under 200 megabytes and not older than 7 days. The discarded logs are deleted.
          sudo journalctl --vacuum-size 200M --vacuum-time 7d
          sudo rm -rf /var/lib/systemd/coredump/*

          # Clean up caches.
          ${runIfCommandExists "pip" "pip cache purge"}
          ${runIfCommandExists "ccache" "ccache -C"}
          ${runIfCommandExists "cargo" "cargo cache -a"}
          #rm -rf ~/.cache/vscode-cpptools/*
          ${getExe pkgs.putzen} caches

          # Clean up Flatpaks.
          ${runIfCommandExists "flatpak" /* sh */ ''
            flatpak uninstall --unused --assumeyes
            sudo flatpak repair
          ''}

          sudo ${getExe' pkgs.trash-cli "trash-empty"} -f --dry-run ; sudo ${getExe' pkgs.trash-cli "trash-empty"}
        '')
      ];
    };
}
