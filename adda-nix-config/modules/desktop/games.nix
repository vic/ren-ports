# games: wine/proton/heroic/steam + RimWorld tooling; umu-jail sandbox as its own package aspect
{ ren, inputs, ... }:
let
  addax = ren.helpers;
in
{
  ren.aspects.games.homeManager =
    {
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        (addax.selfPackages pkgs).umuJail

        # (inputs.omniflake.unified.nur.repos.username.package)

        protonup-qt
        protonup-ng
        protonplus
        wineWow64Packages.unstableFull
        # wineWow64Packages.waylandFull
        winetricks

        heroic
        # bottles

        umu-launcher
        # umu-launcher-unwrapped
        nero-umu

        # RimWorld.
        (addax.omni pkgs).unified.rimsort.packages.rimsort
        (pkgs.callPackage ./_rimstack.nix { src = inputs.rimstack; })
      ];
    };

  ren.aspects.games.nixos = {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };

  ren.aspects.pkg-umuJail = {
    at = ren.system.x86_64-linux;
    packages =
      { system, ... }:
      let
        pkgs = system.legacyPackages;
      in
      {
        # umu-run with no network and a minimal filesystem view; see ./umu-jail.sh for the reasoning
        #  behind each bind. Kept as a package (not just an alias) so Heroic, nero-umu and .desktop
        #  files can point at a real store path.
        umuJail = pkgs.writeShellApplication {
          name = "umu-jail";
          meta.description = "Run umu-run in a bubblewrap sandbox: no network, no $HOME beyond the game's own directory.";
          runtimeInputs = with pkgs; [
            bubblewrap
            coreutils
            umu-launcher
          ];
          text = builtins.readFile ./umu-jail.sh;
        };
      };
  };

  ren.aspects.games.aliases =
    { lib, pkgs, ... }:
    {
      umuj = lib.getExe (addax.selfPackages pkgs).umuJail;
    };
}
