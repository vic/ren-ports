# Based on: https://github.com/hmajid2301/nixicle/blob/a10f7322101d264e9936bb8f5a21dba887338a39/modules/aspects/zellij/default.nix
{ inputs, ... }:
{
  ren.aspects.dev-mux-zellij = {
    flake-inputs = {
      zjstatus.url = "github:dj95/zjstatus";
      gsesh = {
        url = "gitlab:hmajid2301/gsesh";
        inputs.nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    homeManager =
      { pkgs, config, ... }:
      let
        colors = import ./zellij/_colors.nix config;
        statusbar = import ./zellij/_statusbar.nix { inherit pkgs colors; };
        layouts = import ./zellij/_layouts.nix statusbar colors;
      in
      {
        home.packages = [
          (import ./zellij/_zsesh.nix pkgs)
          inputs.gsesh.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        xdg.configFile = {
          "zellij/config.kdl".text = ''
            ${layouts.stylixTheme}

            ${builtins.readFile ./zellij/config.kdl}
          '';
          "zellij/layouts/dev.kdl".text = layouts.layoutDev;
          "zellij/layouts/default.kdl".text = layouts.layoutDefault;
        };

        programs.zellij.enable = true;
      };
  };
}
