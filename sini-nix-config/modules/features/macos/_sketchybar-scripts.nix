# sketchybar scripts: workspace, front app, clock
{ lib, pkgs, c }:
let
# $NAME / $FOCUSED / $INFO are injected by sketchybar at runtime (SC2154).
mkScript =
  {
    name,
    runtimeInputs ? [ ],
    text,
  }:
  lib.getExe (
    pkgs.writeShellApplication {
      inherit name text;
      runtimeInputs = runtimeInputs ++ [ pkgs.sketchybar ];
      excludeShellChecks = [ "SC2154" ];
    }
  );

# The aerospace query is guarded so a not-yet-ready server can't abort the
# script (writeShellApplication runs under `set -euo pipefail`).
workspaceScript = mkScript {
  name = "sketchybar-workspace";
  runtimeInputs = [ pkgs.aerospace ];
  text = ''
    focused="''${FOCUSED:-}"
    if [ -z "$focused" ]; then
      focused="$(aerospace list-workspaces --focused 2>/dev/null || true)"
    fi
    sid="''${NAME#space.}"
    if [ "$sid" = "$focused" ]; then
      sketchybar --set "$NAME" background.color=${c.accent} icon.color=${c.bg}
    else
      sketchybar --set "$NAME" background.color=${c.surface} icon.color=${c.muted}
    fi
  '';
};

frontAppScript = mkScript {
  name = "sketchybar-front-app";
  text = ''sketchybar --set "$NAME" label="''${INFO:-}"'';
};

clockScript = mkScript {
  name = "sketchybar-clock";
  runtimeInputs = [ pkgs.coreutils ];
  text = ''sketchybar --set "$NAME" label="$(date '+%a %d %b  %H:%M')"'';
};
in
{
  inherit mkScript workspaceScript frontAppScript clockScript;
}
