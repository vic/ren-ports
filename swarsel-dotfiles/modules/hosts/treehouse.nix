# treehouse: old hosts/home/aarch64-linux/treehouse/default.nix (standalone home-manager)
{ ren, inputs, ... }:
let
  sw = ren.helpers;
in
{
  ren.home.treehouse.system = ren.system.aarch64-linux;
  ren.aspects.treehouse = {
    at = ren.lib.within ren.home.treehouse; # the users of this home
    includes = [ ren.aspects.profile-dgxspark ];
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {

        imports = lib.optionals (inputs.vbc-nix ? homeManagerModules) [
          inputs.vbc-nix.homeManagerModules.work-remote
          {
            services.work-remote.enable = true;
            nixpkgs.overlays = [ inputs.vbc-nix.overlays.default ];
          }
        ];

        swarselsystems = {
          isLaptop = false;
          wallpaper = sw.root "files/wallpaper/landscape/surfacewp.png";
        };

        services.xcape = {
          enable = true;
          mapExpression.Control_L = "Escape";
        };

        programs = {
          git.signing = {
            format = lib.mkForce "ssh";
            key = lib.mkForce "${config.home.homeDirectory}/.ssh/id_rsa.pub";
          };
          tmux.shell = lib.mkForce (lib.getExe pkgs.bash);
          zellij.settings.default_shell = lib.mkForce "bash";
        };

        home.packages = with pkgs; [
          attic-client
        ];

        nix.settings.max-jobs = lib.mkForce "auto";

      };
  };
}
