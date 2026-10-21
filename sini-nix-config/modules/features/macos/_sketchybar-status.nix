# sketchybar scripts: volume, battery, tailscale
{ pkgs, mkScript, c }:
{
  volumeScript = mkScript {
    name = "sketchybar-volume";
    text = ''
      vol="''${INFO:-0}"
      case "$vol" in (*[!0-9]*) vol=0 ;; esac
      if [ "$vol" -eq 0 ]; then
        icon="󰖁"
      elif [ "$vol" -lt 34 ]; then
        icon="󰕿"
      elif [ "$vol" -lt 67 ]; then
        icon="󰖀"
      else
        icon="󰕾"
      fi
      sketchybar --set "$NAME" icon="$icon" label="''${vol}%"
    '';
  };

  batteryScript = mkScript {
    name = "sketchybar-battery";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      batt="$(/usr/bin/pmset -g batt)"
      pct="$(echo "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
      [ -z "$pct" ] && pct=0
      if echo "$batt" | grep -q 'AC Power'; then
        icon="󰂄"; color=${c.green}
      elif [ "$pct" -le 20 ]; then
        icon="󰁺"; color=${c.red}
      elif [ "$pct" -le 40 ]; then
        icon="󰁻"; color=${c.fg}
      elif [ "$pct" -le 60 ]; then
        icon="󰁾"; color=${c.fg}
      elif [ "$pct" -le 80 ]; then
        icon="󰂀"; color=${c.fg}
      else
        icon="󰁹"; color=${c.green}
      fi
      sketchybar --set "$NAME" icon="$icon" icon.color="$color" label="''${pct}%"
    '';
  };

  tailscaleScript = mkScript {
    name = "sketchybar-tailscale";
    runtimeInputs = [ pkgs.tailscale ];
    text = ''
      if tailscale status >/dev/null 2>&1; then
        sketchybar --set "$NAME" label="up" icon.color=${c.green}
      else
        sketchybar --set "$NAME" label="off" icon.color=${c.muted}
      fi
    '';
  };
}
