{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.aspects.server-packages.nixos =
    {
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        swarselsystems.enabledServerModules = [ "packages" ];
        environment.systemPackages =
          with pkgs;
          [
            gnupg
            nvd
            nix-output-monitor
            ssh-to-age
            git
            emacs
            vim
            sops
            tmux
            busybox
            ndisc6
            tcpdump
            swarsel-deploy
          ]
          ++ lib.optionals (!config.swarselsystems.isMicroVM) [
            swarsel-gens
            swarsel-switch
          ];
      };
    }

  ;
}
