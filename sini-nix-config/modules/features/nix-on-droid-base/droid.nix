# nix-on-droid system baseline (the `droid` class). Supplies what NixOS-oriented
# roles cannot on a Termux host: base packages, nix flags, stateVersion, shell,
# and the home-manager wiring (stateVersion + nixpkgs policy) that a droid host
# would otherwise get from users-home-manager-shared (which it does not include,
# a droid host does not pull roles.default).
{ ... }:
{
  ren.aspects.nix-on-droid-base-droid.droid =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      environment.packages = with pkgs; [
        coreutils
        findutils
        gnugrep
        gnused
        which
        openssh
      ];

      # experimental-features for flakes; keep-* supplies what direnv's NixOS
      # os block would (nix-on-droid has nix.extraOptions, not nix.settings).
      nix.extraOptions = ''
        experimental-features = nix-command flakes
        keep-outputs = true
        keep-derivations = true
      '';

      # Read the nix-on-droid changelog before bumping. Confirm against the
      # pinned nix-on-droid release (stateVersion enum max is 24.05 at rev 55b6449).
      system.stateVersion = "24.05";

      # Login shell. zsh HM config arrives via the zsh shell aspect (homeManager).
      user.shell = "${pkgs.zsh}/bin/zsh";

      # nix-on-droid does not pass osConfig into its home-manager modules, so the
      # bridged home-manager.config needs an explicit home.stateVersion. The droid
      # HM evaluates its own nixpkgs (home-manager.useGlobalPkgs = false), so the
      # system pkgs' allowUnfree (set in the instantiate) does not reach
      # it: set the fleet allowUnfree policy here too.
      #
      # nix-on-droid bridges home.username/homeDirectory from `user.*` itself; Ren has no define-user battery
      # (den forwarded NixOS-style values that conflicted), so the same values are restated as plain definitions
      # (equal strings merge) rather than mkForce.
      home-manager.sharedModules = [
        {
          home.stateVersion = config.system.stateVersion;
          nixpkgs.config.allowUnfree = true;
          home.username = config.user.userName;
          home.homeDirectory = config.user.home;
        }
      ];
    };
}
