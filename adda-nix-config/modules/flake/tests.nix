# tests: some CI checks to ensure this template always works (fulgur builds, adda has helix).
# Feel free to adapt or remove when this repo is yours.
{ ren, inputs, ... }:
{
  ren.aspects.config-tests = {
    at = ren.system.x86_64-linux;
    checks =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
        checkCond = name: cond: pkgs.runCommandLocal name { } (if cond then "touch $out" else "");
        # apple = inputs.self.darwinConfigurations.apple.config;
        # igloo = inputs.self.nixosConfigurations.igloo.config;
        fulgur-nixos = inputs.self.nixosConfigurations.fulgur-nixos.config;
        # alice-at-igloo = igloo.home-manager.users.alice;
        adda-at-fulgur-nixos = fulgur-nixos.home-manager.users.adda;
        # vmBuilds = !pkgs.stdenvNoCC.hostPlatform.isLinux || builtins.pathExists (self'.packages.vm + "/bin/vm");
        # vmIglooBuilds = !pkgs.stdenvNoCC.hostPlatform.isLinux || builtins.pathExists (self'.packages.vmIgloo + "/bin/vm");
        # iglooBuilds = !pkgs.stdenvNoCC.hostPlatform.isLinux || builtins.pathExists igloo.system.build.toplevel;
        fulgur-nixosBuilds =
          !pkgs.stdenvNoCC.hostPlatform.isLinux || builtins.pathExists fulgur-nixos.system.build.toplevel;
        # appleBuilds = !pkgs.stdenvNoCC.isDarwin || builtins.pathExists apple.system.build.toplevel;
      in
      {
        ${system.name} = {
          # "igloo builds" = checkCond "igloo-builds" iglooBuilds;
          "fulgur-nixos builds" = checkCond "fulgur-nixos-builds" fulgur-nixosBuilds;
          # "apple builds" = checkCond "apple-builds" appleBuilds;
          # "vm builds" = checkCond "vm-builds" vmBuilds;
          # "vmIgloo builds" = checkCond "vm-builds" vmIglooBuilds;

          # "alice enabled igloo nh" = checkCond "alice.provides.igloo" igloo.programs.nh.enable;
          # "adda enabled fulgur-nixos nh" =
          #   checkCond "adda.provides.fulgur-nixos" fulgur-nixos.programs.nh.enable;
          # "igloo enabled alice helix" =
          #   checkCond "igloo.provides.alice" alice-at-igloo.programs.helix.enable;
          "fulgur-nixos enabled adda helix" =
            checkCond "fulgur-nixos.provides.adda" adda-at-fulgur-nixos.programs.helix.enable;

          # "alice-custom-emacs" = checkCond "hm.programs.emacs.package" (
          #   "emacs-nox" == lib.getName alice-at-igloo.programs.emacs.package
          # );
        };
      };
  };
}
