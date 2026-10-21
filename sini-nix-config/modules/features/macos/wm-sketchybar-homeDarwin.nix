# SketchyBar: a floating "islands" status bar themed from the stylix base16
# palette and the stylix monospace (Nerd) font. The bar itself is transparent
# (no full-width blurred strip) — each item/group carries its own pill.
# Left: aerospace workspace pills + focused app. Right: volume, battery, clock,
# tailscale grouped in one pill. Bar config text: wm-sketchybar-homeDarwin-rc.nix.
{ ... }:
{
  ren.aspects.macos-wm-sketchybar-homeDarwin.homeDarwin =
    { config, pkgs, ... }:
    {
      programs.sketchybar = {
        enable = true;
        service.enable = true;
        extraPackages = with pkgs; [
          aerospace
          coreutils
          gnugrep
          tailscale
        ];
      };

      # home-manager doesn't restart the launchd agent when only the (fixed-path)
      # sketchybarrc content changes, so kickstart it on activation to load the
      # new config.
      home.activation.restartSketchybar = config.lib.dag.entryAfter [ "setupLaunchAgents" ] ''
        run /bin/launchctl kickstart -k "gui/$UID/org.nix-community.home.sketchybar" || true
      '';
    };
}
